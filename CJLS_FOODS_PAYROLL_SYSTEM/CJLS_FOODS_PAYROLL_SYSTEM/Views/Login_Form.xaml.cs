﻿using System;
using System.Collections.Generic;
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
using System.Windows.Shapes;

namespace CJLS_FOODS_PAYROLL_SYSTEM.Views
{
    /// <summary>
    /// Interaction logic for Login_Form.xaml
    /// </summary>
    public partial class Login_Form : Window
    {
        View_Models.LoginViewModel VM;
        public Login_Form()
        {
            InitializeComponent();
            VM = (View_Models.LoginViewModel)DataContext;
        }

        private void btn_Login_Click(object sender, RoutedEventArgs e)
        {
            VM.Password = passwordBox.Password;
            VM.CheckLogin();
        }
    }
}