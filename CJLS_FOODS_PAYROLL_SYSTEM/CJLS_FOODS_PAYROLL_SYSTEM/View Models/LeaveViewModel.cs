﻿using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CJLS_FOODS_PAYROLL_SYSTEM.View_Models
{
    public class LeaveViewModel : INotifyPropertyChanged
    {
        public LeaveViewModel()
        {
            Leave = new Leave();
            Leaves = new ObservableCollection<Leave>();
            Employees = new List<Employee>();
            GetLeaves();
            GetEmployees();
        }
        public Leave Leave { get; set; }
        public ObservableCollection<Leave> Leaves { get; set; }
        public List<Employee> Employees { get; set; }
        public Employee Employee { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;

        public void CreateNewLeave()
        {
            try
            {
                Helper.db.Leaves.InsertOnSubmit(Leave);
                Leaves.Add(Leave);
                Helper.db.SubmitChanges();
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        public void UpdateLeave()
        {
            Helper.db.SubmitChanges();
        }
        private void GetLeaves()
        {
            Leaves = new ObservableCollection<Leave>((from l in Helper.db.Leaves select l).ToList());
        }
        public void DeleteLeave(Leave Leave)
        {
            Helper.db.Leaves.DeleteOnSubmit(Leave);
            Leaves.Remove(Leave);
            Leave = new Leave();
            Helper.db.SubmitChanges();
            MessageBox.Show("Successfully Deleted Employee Group!");
        }

        public void GetEmployees()
        {
            Employees = (from e in Helper.db.Employees select e).ToList();
        }
    }
}