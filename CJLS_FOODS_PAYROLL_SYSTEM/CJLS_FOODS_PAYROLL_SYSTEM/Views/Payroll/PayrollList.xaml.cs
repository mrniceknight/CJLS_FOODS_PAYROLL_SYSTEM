﻿using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace CJLS_FOODS_PAYROLL_SYSTEM.Views.PayrollView
{
    /// <summary>
    /// Interaction logic for Payroll.xaml
    /// </summary>
    public partial class PayrollList : Page
    {
        View_Models.PayrollViewModel VM;
        public PayrollList()
        {
            InitializeComponent();
            VM = (View_Models.PayrollViewModel)DataContext;
            VM.Instantiate();
        }

        private void Btn_OpenDialogCreate_Click(object sender, RoutedEventArgs e)
        {
            VM.Payroll = new Payroll() { StartDate = DateTime.Now, EndDate = DateTime.Now };
            DialogHeader.Text = "Create New Payroll";
            btn_dialogConfirm.Content = "CREATE";
        }

        private void btn_DialogConfirm_Click(object sender, RoutedEventArgs e)
        {
            VM.CreateEmployeePayrollDetails();
            VM.Payroll.DateCreated = DateTime.Now.Date;
            Helper.db.Payrolls.InsertOnSubmit(VM.Payroll);
            Helper.db.SubmitChanges();
            Helper.db.Refresh(System.Data.Linq.RefreshMode.OverwriteCurrentValues, VM.Payroll);
            Helper.Title.Text = "Payroll Details";
            NavigationService.Navigate(new Views.PayrollView.PayrollDetails(VM.Payroll));
            VM.Payroll = new Payroll() { StartDate = DateTime.Now, EndDate = DateTime.Now };
        }

        private void Btn_viewPayroll_Click(object sender, RoutedEventArgs e)
        {
            Helper.Title.Text = "Payroll Details";
            NavigationService.Navigate(new Views.PayrollView.PayrollDetails(VM.Payroll));
            VM.Payroll = new Payroll() { StartDate = DateTime.Now, EndDate = DateTime.Now };
        }

        private void btn_deletePayroll_Click(object sender, RoutedEventArgs e)
        {
            var res = MessageBox.Show("Are you sure you want to delete it?", "Delete Payroll", MessageBoxButton.YesNo);
            if (res == MessageBoxResult.Yes)
                VM.deletePayroll(VM.Payroll);
        }

        private void Page_Loaded(object sender, RoutedEventArgs e)
        {
            VM = (View_Models.PayrollViewModel)DataContext;
            VM.Instantiate();
        }
        private void ComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            VM.Payroll.LatestEndDate = (from p in Helper.db.Payrolls where p.PayrollGroup.PayrollGroupID == VM.Payroll.PayrollGroupID select p.EndDate).FirstOrDefault();
        }
        private void btn_previousPage_Click(object sender, RoutedEventArgs e)
        {
            VM.Page--;
            VM.Payrolls = VM.GetPagedResult();
        }

        private void btn_nextPage_Click(object sender, RoutedEventArgs e)
        {
            VM.Page++;
            VM.Payrolls = VM.GetPagedResult();
        }
        private void TextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            VM.Page = 0;
            string search = VM.Search.ToLower();
            if (!String.IsNullOrEmpty(search))
                VM.FilteredResult = new ObservableCollection<Payroll>((from b in Helper.db.Payrolls where b.StartDate.Date.ToString().Contains(search) || b.EndDate.Date.ToString().Contains(search) || b.PayrollGroup.Name.Contains(search) || b.PayrollID.ToString().Contains(search) select b).ToList().Skip(VM.Page * 10).Take(10));
            else
                VM.FilteredResult = VM.FetchPayrollList();
            VM.Payrolls = new ObservableCollection<Payroll>(VM.FilteredResult.Skip(VM.Page * 10).Take(10));
        }
    }
}
