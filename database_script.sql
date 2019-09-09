USE [master]
GO
/****** Object:  Database [CJLSFOODSPAYROLL]    Script Date: 9/9/2019 8:27:11 PM ******/
CREATE DATABASE [CJLSFOODSPAYROLL]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'CJLSFOODSPAYROLL', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\CJLSFOODSPAYROLL.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'CJLSFOODSPAYROLL_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\CJLSFOODSPAYROLL_log.ldf' , SIZE = 335872KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [CJLSFOODSPAYROLL].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ARITHABORT OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET  DISABLE_BROKER 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET  MULTI_USER 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET DB_CHAINING OFF 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET QUERY_STORE = OFF
GO
USE [CJLSFOODSPAYROLL]
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeContribution]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeContribution](
@ContributionTypeID int,
@PayrollDetailID int
)
returns float
as
begin
declare @AverageMonthlyWorkingDays as float = (select IIF(RequiredDaysAWeek=5,261,IIF(RequiredDaysAWeek=6,313,0))/12.0 from PayrollDetail inner join Employee on PayrollDetail.EmployeeID = Employee.EmployeeID where PayrollDetailID=@PayrollDetailID)
declare @TotalDays as int = (select TotalDays from PayrollDetail where PayrollDetailID=@PayrollDetailID)
declare @MonthlySalary as float = (select MonthlySalary from PayrollDetail inner join Employee on PayrollDetail.EmployeeID = Employee.EmployeeID where PayrollDetailID = @PayrollDetailID)
declare @Grosspay as float = (select GrossPay from PayrollDetail where PayrollDetailID=@PayrollDetailID)
declare @Amount as float
if(@ContributionTypeID=1)
	return dbo.ComputePhilHealth(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays);
else if(@ContributionTypeID=2)
	return dbo.ComputeSSS(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays);
else if(@ContributionTypeID=3)
	return dbo.ComputePagibig(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays);
else if(@ContributionTypeID=4)
	return dbo.ComputeTax(@Grosspay,@AverageMonthlyWorkingDays,@TotalDays);
return 0;
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeGrossPay]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ComputeGrossPay](@EmployeeID int, @PayrollDetailID int)
returns float
as
begin
declare @TotalRegularHours as float = (select TotalRegularHours from PayrollDetail where PayrollDetailID = @PayrollDetailID)
declare @HourlyRate as float = (select HOurlyRate from Employee where EmployeeID = @EmployeeID)
return @TotalRegularHours*@HourlyRate+dbo.ComputeOVertime(@EmployeeID,@PayrollDetailID)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeNetPay]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeNetPay](@PayrollDetailID float)
returns float
as
begin
declare @GrossPay as float = (select GrossPay from PayrollDetail where PayrollDetailID=@PayrollDetailID)
declare @Deductions as float = ISNULL((select TotalDeductions from PayrollDetail where PayrollDetailID=@PayrollDetailID),0)
return @GrossPay-@Deductions
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeOverTime]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeOverTime](@EmployeeID int, @PayrollDetailID int)
returns float
as
begin
declare @TotalOvertimeHours as float = (select TotalOverTimeHours from PayrollDetail where PayrollDetailID = @PayrollDetailID)
declare @HourlyRate as float = (select HOurlyRate from Employee where EmployeeID = @EmployeeID)	
return @TotalOvertimeHours*(@HourlyRate*1.25)
end

GO
/****** Object:  UserDefinedFunction [dbo].[ComputePagIBIG]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ComputePagIBIG](@MonthlySalary float, @AverageWorkDaysAMonth float, @TotalDays float)
returns float
as
BEGIN
declare @PAGIBIGRate as float;
set @PAGIBIGRate = (select PercentageRate from ContributionType where Name='Pagibig')
IF @MonthlySalary <= 1500
	set @PAGIBIGRate=0.01
ELSE
	set @PAGIBIGRate=0.02
IF @MonthlySalary > 5000
	set @MonthlySalary = 5000
return round(@MonthlySalary*@PAGIBIGRate/@AverageWorkDaysAMonth*@TotalDays,2)
END
GO
/****** Object:  UserDefinedFunction [dbo].[computePayment]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[computePayment](@LoanID int)
returns float
as
begin
return round((select Amount/Terms from Loan where LoanID=@LoanID),2)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputePhilHealth]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ComputePhilHealth](@MonthlySalary float, @AverageWorkDaysAMonth float, @TotalDays float)
RETURNS FLOAT
AS
BEGIN
IF @MonthlySalary < 10000
	SET @MonthlySalary = 10000
ELSE 
BEGIN 
	IF @MonthlySalary > 40000
		SET @MonthlySalary = 40000
END
declare @PhilHealthRate float;
set @PhilHealthRate = (select PercentageRate from ContributionType where Name='PhilHealth')
return round(@MonthlySalary*@PhilHealthRate/2/@AverageWorkDaysAMonth*@TotalDays,2)
END
GO
/****** Object:  UserDefinedFunction [dbo].[computeRegularPay]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[computeRegularPay](@PayrollDetailID int,@employeeID int)
returns float
as
begin
declare @hourlyRate as float = (select HourlyRate from Employee where EmployeeID=@employeeID)
declare @TotalRegularHours as int = (select TotalRegularHours from PayrollDetail where PayrollDetailID=@PayrollDetailID)
return round(@hourlyRate * @TotalRegularHours,2)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeSSS]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ComputeSSS](@MonthlySalary float, @AverageWorkDaysAMonth float,@TotalDays float)
returns float
as
BEGIN
declare @MSC as float
declare @SSSRate as float
set @SSSRate = (select ContributionType.PercentageRate from ContributionType where Name='SSS')

IF @MonthlySalary < 2250
	set @MSC = 2000.00;
ELSE
	BEGIN
		IF @MonthlySalary >= 19750
		set @MSC = 20000.00;
		ELSE
			BEGIN			
				set @MSC = round(@MonthlySalary/500,0)*500 -- round off by 500 to get to nearest MSC
			END
	END
return round(@MSC*@SSSRATE/@AverageWorkDaysAMonth*@TotalDays,2)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeTax]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeTax](@DeductedMonthlySalary float, @AverageWorkDaysAMonth float,@TotalDays float)
returns float
as
begin
declare @TaxPercentRate as float = 0;
declare @CLAmount as float = 0;
declare @Total as float = 0;

if @DeductedMonthlySalary <= 20833/@AverageWorkDaysAMonth*@TotalDays
	set @TaxPercentRate = 0;
if @DeductedMonthlySalary > 20833 and @DeductedMonthlySalary < 33333
	begin
	set @TaxPercentRate = 0.2;
	set @CLAmount = 20833/@AverageWorkDaysAMonth*@TotalDays;
	end
if @DeductedMonthlySalary >= 33333/@AverageWorkDaysAMonth*@TotalDays and @DeductedMonthlySalary < 66667/@AverageWorkDaysAMonth*@TotalDays
	begin
	set @Total = 2500/@AverageWorkDaysAMonth*@TotalDays;
	set @TaxPercentRate = 0.25;
	set @CLAmount = 33333/@AverageWorkDaysAMonth*@TotalDays;
	end
if @DeductedMonthlySalary >= 66667/@AverageWorkDaysAMonth*@TotalDays and @DeductedMonthlySalary < 166667/@AverageWorkDaysAMonth*@TotalDays
	begin
	set @Total = 10833.33/@AverageWorkDaysAMonth*@TotalDays;
	set @TaxPercentRate = 0.30;
	set @CLAmount = 66667/@AverageWorkDaysAMonth*@TotalDays;
	end
if @DeductedMonthlySalary >= 166667/@AverageWorkDaysAMonth*@TotalDays and @DeductedMonthlySalary < 666667/@AverageWorkDaysAMonth*@TotalDays
	begin
	set @Total = 40833.33/@AverageWorkDaysAMonth*@TotalDays
	set @TaxPercentRate = 0.32;
	set @CLAmount = 166667/@AverageWorkDaysAMonth*@TotalDays;
	end
if @DeductedMonthlySalary >= 666667/@AverageWorkDaysAMonth*@TotalDays
	begin
	set @Total = 200833.33/@AverageWorkDaysAMonth*@TotalDays
	set @TaxPercentRate = 0.35;
	set @CLAmount = 666667/@AverageWorkDaysAMonth*@TotalDays;
	end

return round(((@DeductedMonthlySalary-@CLAmount)*@TaxPercentRate+@Total)/@AverageWorkDaysAMonth*@TotalDays,2);
end
GO
/****** Object:  UserDefinedFunction [dbo].[computeTermsRemaining]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[computeTermsRemaining](@LoanID int, @Terms int)
returns int
as
begin
return (select @Terms-count(*) from LoanPayment where LoanID = @LoanID)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeTotalContributions]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeTotalContributions](@EmployeeID int, @PayrollDetailID int, @PayrollID int)
returns float
as
begin
declare @MonthlySalary as float = (select Employee.MonthlySalary from Employee where EmployeeID=@EmployeeID)
declare @GrossPay as float = (select PayrollDetail.GrossPay from PayrollDetail where PayrollDetailID=@PayrollDetailID)
declare @TotalDays as float = (select PayrollDetail.TotalDays from PayrollDetail where PayrollDetailID=@PayrollDetailID and PayrollID=@PayrollID)
declare @AverageMonthlyWorkingDays as float = (select IIF(RequiredDaysAWeek=5,261,IIF(RequiredDaysAWeek=6,313,0))/12.0 from Employee where EmployeeID=@EmployeeID)

--var declarations
declare @SSS float, @PAGIBIG float, @PHILHEALTH float, @DeductedMonthlySalary float,
		@TAX float
IF (select Employee.IsSSSActive from Employee where EmployeeID=@EmployeeID)=1
 set @SSS = (select dbo.ComputeSSS(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays));
ELSE
set @SSS = 0;
IF (select Employee.IsPagibigActive from Employee where EmployeeID=@EmployeeID)=1
set @PAGIBIG = (select dbo.ComputePagIBIG(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays));
ELSE
set @PAGIBIG = 0;
IF (select Employee.IsPhilhealthActive from Employee where EmployeeID=@EmployeeID)=1
set @PHILHEALTH = (select dbo.ComputePhilHealth(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays));
ELSE
set @PHILHEALTH = 0;
IF (select Employee.IsPhilhealthActive from Employee where EmployeeID=@EmployeeID)=1
set @PHILHEALTH = (select dbo.ComputePhilHealth(@MonthlySalary,@AverageMonthlyWorkingDays,@TotalDays));
ELSE
set @PHILHEALTH = 0;

set @DeductedMonthlySalary = @GrossPay-@SSS-@PAGIBIG-@PHILHEALTH;

IF (select Employee.IsIncomeTaxActive from Employee where EmployeeID=@EmployeeID)=1
set @TAX = (select dbo.ComputeTax(@DeductedMonthlySalary,@AverageMonthlyWorkingDays,@TotalDays));
ELSE
set @TAX = 0;
return @SSS+@PAGIBIG+@PHILHEALTH+@TAX
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeTotalDeductions]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ComputeTotalDeductions](@PayrollDetailID int)
returns float
as
begin
declare @dayToDayDeduction as float = (select sum(isnull(deduction.amount,0)) from Attendance left join Deduction on Attendance.AttendanceID=Deduction.AttendanceID where Attendance.PayrollDetailsID = @PayrollDetailID)
declare @loanPayment as float = (select sum(isnull(loanpayment.amountpaid,0)) from LoanPayment where LoanPayment.PayrollDetailID = @PayrollDetailID)
declare @contribution as float = (select sum(isnull(contribution.amount,0)) from Contribution where Contribution.PayrollDetailID = @PayrollDetailID)

return round(isnull(@dayToDayDeduction,0)+isnull(@loanPayment,0)+isnull(@contribution,0),2)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeTotalOverTimeHours]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ComputeTotalOverTimeHours](@PayrollDetailID float)
returns float
as
begin
return (select SUM(OverTimeHoursWorked) from Attendance where PayrollDetailsID=@PayrollDetailID)
end
GO
/****** Object:  UserDefinedFunction [dbo].[ComputeTotalRegularHours]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ComputeTotalRegularHours](@PayrollDetailID float)
returns float
as
begin
return (select SUM(RegularHoursWorked) from Attendance where PayrollDetailsID=@PayrollDetailID)
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetTotalDaysOf]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[GetTotalDaysOf](@PayrollDetailsID int)
returns int
as
begin
return (select count(*) from Attendance where PayrollDetailsID=@PayrollDetailsID and RegularHoursWorked>0)
end
GO
/****** Object:  Table [dbo].[Attendance]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attendance](
	[AttendanceDate] [datetime] NULL,
	[RegularHoursWorked] [float] NOT NULL,
	[OverTimeHoursWorked] [float] NOT NULL,
	[AttendanceID] [int] IDENTITY(1,1) NOT NULL,
	[PayrollDetailsID] [int] NULL,
	[MinutesLate] [float] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AttendanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Contribution]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contribution](
	[ContributionLogID] [int] IDENTITY(1,1) NOT NULL,
	[ContributionTypeID] [int] NULL,
	[PayrollDetailID] [int] NULL,
	[Amount]  AS ([dbo].[ComputeContribution]([ContributionTypeID],[PayrollDetailID])),
PRIMARY KEY CLUSTERED 
(
	[ContributionLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContributionType]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContributionType](
	[ContributionTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[PercentageRate] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[ContributionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Deduction]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Deduction](
	[DeductionsLogId] [int] IDENTITY(1,1) NOT NULL,
	[DeductionTypeID] [int] NULL,
	[Amount] [float] NOT NULL,
	[AttendanceID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[DeductionsLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeductionsTypes]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionsTypes](
	[DeductionTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[DeductionReferenceId] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[DeductionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Employee]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee](
	[EmployeeID] [int] IDENTITY(1000,1) NOT NULL,
	[EmployeeGroupID] [int] NOT NULL,
	[EmployeeTypeID] [int] NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[MiddleName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[FullName]  AS (([FirstName]+' ')+[LastName]),
	[Gender] [varchar](25) NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[Age]  AS (datediff(year,[DateOfBirth],getdate())),
	[ContactNumber] [varchar](50) NOT NULL,
	[Address] [varchar](255) NOT NULL,
	[AvailableLeaves] [int] NOT NULL,
	[HourlyRate] [float] NOT NULL,
	[DailyRequiredHours] [int] NOT NULL,
	[DailyRate]  AS ([HourlyRate]*[DailyRequiredHours]),
	[RequiredDaysAWeek] [int] NOT NULL,
	[MonthlySalary]  AS (round((([HourlyRate]*[DailyRequiredHours])*case when [RequiredDaysAWeek]=(5) then (261) else case when [RequiredDaysAWeek]=(6) then (313)  end end)/(12),(2))) PERSISTED,
	[SSSID] [varchar](50) NULL,
	[PagIbigID] [varchar](50) NULL,
	[PhilhealthID] [varchar](50) NULL,
	[TINID] [varchar](50) NULL,
	[Branch] [varchar](50) NULL,
	[Status] [varchar](50) NOT NULL,
	[IsPhilhealthActive] [bit] NOT NULL,
	[IsSSSActive] [bit] NOT NULL,
	[IsIncomeTaxActive] [bit] NOT NULL,
	[IsPagibigActive] [bit] NOT NULL,
 CONSTRAINT [PK__Employee__7AD04FF1FDB489B5] PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeType]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeType](
	[EmployeeTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Leave]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Leave](
	[LeaveID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[LeaveDate] [date] NOT NULL,
	[IsPaidLeave] [bit] NOT NULL,
 CONSTRAINT [PK__Leave__796DB979F4C0C9AE] PRIMARY KEY CLUSTERED 
(
	[LeaveID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Loan]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Loan](
	[LoanID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[Amount] [float] NULL,
	[LoanType] [varchar](50) NOT NULL,
	[Terms] [int] NOT NULL,
	[TermsRemaining]  AS ([dbo].[computeTermsRemaining]([LoanID],[Terms])),
	[AmountRemaining]  AS ([dbo].[computeTermsRemaining]([LoanID],[Terms])*([Amount]/[Terms])),
	[TotalPaid]  AS (([Terms]-[dbo].[computeTermsRemaining]([LoanID],[Terms]))*([Amount]/[Terms])),
	[IsPaid]  AS (CONVERT([bit],case when [dbo].[computeTermsRemaining]([LoanID],[Terms])>(0) then (0) else (1) end)),
	[AmountPerPayroll]  AS (round([Amount]/[Terms],(2))),
 CONSTRAINT [PK__Loan__4F5AD43784B9B230] PRIMARY KEY CLUSTERED 
(
	[LoanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoanPayment]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPayment](
	[LoanPaymentID] [int] IDENTITY(1,1) NOT NULL,
	[LoanID] [int] NOT NULL,
	[PayrollDetailID] [int] NOT NULL,
	[AmountPaid]  AS ([dbo].[computePayment]([LoanID])),
 CONSTRAINT [PK__LoanPaym__5BA74D5C6DAD6842] PRIMARY KEY CLUSTERED 
(
	[LoanPaymentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payroll]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payroll](
	[PayrollID] [int] IDENTITY(1,1) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[PayrollGroupID] [int] NULL,
	[DateCreated] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PayrollID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PayrollDetail]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayrollDetail](
	[PayrollDetailID] [int] IDENTITY(1,1) NOT NULL,
	[PayrollID] [int] NULL,
	[EmployeeID] [int] NULL,
	[TotalDays]  AS ([dbo].[GetTotalDaysOf]([PayrollDetailID])),
	[TotalRegularHours]  AS ([dbo].[ComputeTotalRegularHours]([PayrollDetailID])),
	[TotalOverTimeHours]  AS ([dbo].[ComputeTotalOvertimeHours]([PayrollDetailID])),
	[RegularPay]  AS ([dbo].[computeRegularPay]([PayrollDetailID],[EmployeeID])),
	[OvertimePay]  AS ([dbo].[computeOvertime]([EmployeeID],[PayrollDetailID])),
	[GrossPay]  AS ([dbo].[ComputeRegularPay]([PayrollDetailID],[EmployeeID])+[dbo].[ComputeOvertime]([EmployeeID],[PayrollDetailID])),
	[TotalContributions]  AS ([dbo].[computetotalcontributions]([EmployeeID],[PayrollDetailID],[PayrollID])),
	[TotalDeductions]  AS ([dbo].[ComputeTotalDeductions]([PayrollDetailID])),
	[NetPay]  AS ([dbo].[ComputeNetPay]([PayrollDetailID])),
 CONSTRAINT [PK__PayrollD__010127A9AB92AB29] PRIMARY KEY CLUSTERED 
(
	[PayrollDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PayrollGroup]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayrollGroup](
	[PayrollGroupID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[PayrollGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[FullName] [varchar](50) NULL,
	[Username] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[SecretQuestion] [varchar](50) NULL,
	[SecretAnswer] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[Attendance] ON 

INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-03T00:00:00.000' AS DateTime), 8, 0, 2216, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-04T00:00:00.000' AS DateTime), 8, 0, 2217, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-05T00:00:00.000' AS DateTime), 8, 0, 2218, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-06T00:00:00.000' AS DateTime), 8, 0, 2219, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-07T00:00:00.000' AS DateTime), 8, 0, 2220, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-08T00:00:00.000' AS DateTime), 8, 0, 2221, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-09T00:00:00.000' AS DateTime), 8, 0, 2222, 1248, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-06T00:00:00.000' AS DateTime), 12, 0, 2223, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-07T00:00:00.000' AS DateTime), 12, 0, 2224, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-08T00:00:00.000' AS DateTime), 12, 0, 2225, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-09T00:00:00.000' AS DateTime), 12, 0, 2226, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-10T00:00:00.000' AS DateTime), 12, 0, 2227, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-11T00:00:00.000' AS DateTime), 12, 0, 2228, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-12T00:00:00.000' AS DateTime), 12, 0, 2229, 1252, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-06T00:00:00.000' AS DateTime), 8, 0, 2230, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-07T00:00:00.000' AS DateTime), 8, 0, 2231, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-08T00:00:00.000' AS DateTime), 8, 0, 2232, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-09T00:00:00.000' AS DateTime), 8, 0, 2233, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-10T00:00:00.000' AS DateTime), 8, 0, 2234, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-11T00:00:00.000' AS DateTime), 8, 0, 2235, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-12T00:00:00.000' AS DateTime), 8, 0, 2236, 1249, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-06T00:00:00.000' AS DateTime), 8, 0, 2237, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-07T00:00:00.000' AS DateTime), 8, 0, 2238, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-08T00:00:00.000' AS DateTime), 8, 0, 2239, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-09T00:00:00.000' AS DateTime), 8, 0, 2240, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-10T00:00:00.000' AS DateTime), 8, 0, 2241, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-11T00:00:00.000' AS DateTime), 8, 0, 2242, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-12T00:00:00.000' AS DateTime), 8, 0, 2243, 1251, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-06T00:00:00.000' AS DateTime), 12, 0, 2244, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-07T00:00:00.000' AS DateTime), 12, 0, 2245, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-08T00:00:00.000' AS DateTime), 12, 0, 2246, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-09T00:00:00.000' AS DateTime), 12, 0, 2247, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-10T00:00:00.000' AS DateTime), 12, 0, 2248, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-11T00:00:00.000' AS DateTime), 12, 0, 2249, 1253, 0)
INSERT [dbo].[Attendance] ([AttendanceDate], [RegularHoursWorked], [OverTimeHoursWorked], [AttendanceID], [PayrollDetailsID], [MinutesLate]) VALUES (CAST(N'2019-09-12T00:00:00.000' AS DateTime), 12, 0, 2250, 1253, 0)
SET IDENTITY_INSERT [dbo].[Attendance] OFF
SET IDENTITY_INSERT [dbo].[Contribution] ON 

INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (249, 1, 1248)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (250, 2, 1248)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (251, 3, 1248)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (252, 4, 1248)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (253, 1, 1249)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (254, 2, 1249)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (255, 3, 1249)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (256, 4, 1249)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (257, 1, 1250)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (258, 2, 1250)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (259, 1, 1251)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (260, 2, 1251)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (261, 3, 1251)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (262, 4, 1251)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (263, 1, 1252)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (264, 2, 1252)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (265, 1, 1253)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (266, 2, 1253)
INSERT [dbo].[Contribution] ([ContributionLogID], [ContributionTypeID], [PayrollDetailID]) VALUES (267, 3, 1253)
SET IDENTITY_INSERT [dbo].[Contribution] OFF
SET IDENTITY_INSERT [dbo].[ContributionType] ON 

INSERT [dbo].[ContributionType] ([ContributionTypeID], [Name], [PercentageRate]) VALUES (1, N'PhilHealth', 0.0275)
INSERT [dbo].[ContributionType] ([ContributionTypeID], [Name], [PercentageRate]) VALUES (2, N'SSS', 0.04)
INSERT [dbo].[ContributionType] ([ContributionTypeID], [Name], [PercentageRate]) VALUES (3, N'Pagibig', 0.02)
INSERT [dbo].[ContributionType] ([ContributionTypeID], [Name], [PercentageRate]) VALUES (4, N'Tax', 0)
SET IDENTITY_INSERT [dbo].[ContributionType] OFF
SET IDENTITY_INSERT [dbo].[Deduction] ON 

INSERT [dbo].[Deduction] ([DeductionsLogId], [DeductionTypeID], [Amount], [AttendanceID]) VALUES (13, 3, 25, 2218)
INSERT [dbo].[Deduction] ([DeductionsLogId], [DeductionTypeID], [Amount], [AttendanceID]) VALUES (14, 3, 25, 2223)
INSERT [dbo].[Deduction] ([DeductionsLogId], [DeductionTypeID], [Amount], [AttendanceID]) VALUES (15, 3, 25, 2224)
INSERT [dbo].[Deduction] ([DeductionsLogId], [DeductionTypeID], [Amount], [AttendanceID]) VALUES (1015, 6, 125, 2229)
SET IDENTITY_INSERT [dbo].[Deduction] OFF
SET IDENTITY_INSERT [dbo].[DeductionsTypes] ON 

INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (1, N'Sales Short', N'DED_SALE_SHORT')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (2, N'Inventory', N'DED_INVENTORY')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (3, N'Excess Meal', N'DED_EXCSS_MEAL')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (4, N'Incomplete Uniform', N'DED_INC_UNIFROM')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (5, N'Cash Advance/Loan', N'DED_CA_')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (6, N'Late', N'DED_LATE')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (7, N'Inventory', N'DED_INVENTORY')
INSERT [dbo].[DeductionsTypes] ([DeductionTypeID], [Name], [DeductionReferenceId]) VALUES (8, N'Cash Advance/Loan', N'DED_CA_')
SET IDENTITY_INSERT [dbo].[DeductionsTypes] OFF
SET IDENTITY_INSERT [dbo].[Employee] ON 

INSERT [dbo].[Employee] ([EmployeeID], [EmployeeGroupID], [EmployeeTypeID], [FirstName], [MiddleName], [LastName], [Gender], [DateOfBirth], [ContactNumber], [Address], [AvailableLeaves], [HourlyRate], [DailyRequiredHours], [RequiredDaysAWeek], [SSSID], [PagIbigID], [PhilhealthID], [TINID], [Branch], [Status], [IsPhilhealthActive], [IsSSSActive], [IsIncomeTaxActive], [IsPagibigActive]) VALUES (1028, 7, 4, N'slkdj', N'aslkdj', N'aslkd', N'Male', CAST(N'1998-10-04T00:00:00.000' AS DateTime), N'aslkdj', N'sadj', 5, 50, 8, 6, NULL, NULL, NULL, NULL, N'Main', N'Active', 1, 1, 1, 1)
INSERT [dbo].[Employee] ([EmployeeID], [EmployeeGroupID], [EmployeeTypeID], [FirstName], [MiddleName], [LastName], [Gender], [DateOfBirth], [ContactNumber], [Address], [AvailableLeaves], [HourlyRate], [DailyRequiredHours], [RequiredDaysAWeek], [SSSID], [PagIbigID], [PhilhealthID], [TINID], [Branch], [Status], [IsPhilhealthActive], [IsSSSActive], [IsIncomeTaxActive], [IsPagibigActive]) VALUES (1029, 7, 3, N'Neil Francis', N'Agsoy', N'Nahid', N'Male', CAST(N'1998-10-04T00:00:00.000' AS DateTime), N'09289066258', N'Looc Norte, Asturias, Cebu', 5, 50, 12, 5, N'1234', N'123', N'312', NULL, N'Main', N'Active', 1, 1, 0, 0)
INSERT [dbo].[Employee] ([EmployeeID], [EmployeeGroupID], [EmployeeTypeID], [FirstName], [MiddleName], [LastName], [Gender], [DateOfBirth], [ContactNumber], [Address], [AvailableLeaves], [HourlyRate], [DailyRequiredHours], [RequiredDaysAWeek], [SSSID], [PagIbigID], [PhilhealthID], [TINID], [Branch], [Status], [IsPhilhealthActive], [IsSSSActive], [IsIncomeTaxActive], [IsPagibigActive]) VALUES (1030, 7, 3, N'Nikko', N'Agsoy', N'Nahid', N'Male', CAST(N'1997-12-04T00:00:00.000' AS DateTime), N'09289066258', N'Looc Norte', 5, 50, 12, 5, N'123 ', N'12333', N'ccc', NULL, N'Main', N'Active', 1, 1, 0, 1)
SET IDENTITY_INSERT [dbo].[Employee] OFF
SET IDENTITY_INSERT [dbo].[EmployeeType] ON 

INSERT [dbo].[EmployeeType] ([EmployeeTypeID], [Name]) VALUES (3, N'Crew')
INSERT [dbo].[EmployeeType] ([EmployeeTypeID], [Name]) VALUES (4, N'Cashier')
INSERT [dbo].[EmployeeType] ([EmployeeTypeID], [Name]) VALUES (5, N'Admin')
INSERT [dbo].[EmployeeType] ([EmployeeTypeID], [Name]) VALUES (6, N'Commissary')
SET IDENTITY_INSERT [dbo].[EmployeeType] OFF
SET IDENTITY_INSERT [dbo].[Leave] ON 

INSERT [dbo].[Leave] ([LeaveID], [EmployeeID], [LeaveDate], [IsPaidLeave]) VALUES (10, 1028, CAST(N'2019-09-03' AS Date), 0)
INSERT [dbo].[Leave] ([LeaveID], [EmployeeID], [LeaveDate], [IsPaidLeave]) VALUES (11, 1028, CAST(N'2019-11-01' AS Date), 0)
SET IDENTITY_INSERT [dbo].[Leave] OFF
SET IDENTITY_INSERT [dbo].[Loan] ON 

INSERT [dbo].[Loan] ([LoanID], [EmployeeID], [Amount], [LoanType], [Terms]) VALUES (7, 1028, 5000, N'Loan', 3)
INSERT [dbo].[Loan] ([LoanID], [EmployeeID], [Amount], [LoanType], [Terms]) VALUES (8, 1028, 500, N'Cash Advance', 1)
INSERT [dbo].[Loan] ([LoanID], [EmployeeID], [Amount], [LoanType], [Terms]) VALUES (9, 1028, 300, N'Loan', 3)
INSERT [dbo].[Loan] ([LoanID], [EmployeeID], [Amount], [LoanType], [Terms]) VALUES (10, 1028, 300, N'Loan', 3)
INSERT [dbo].[Loan] ([LoanID], [EmployeeID], [Amount], [LoanType], [Terms]) VALUES (11, 1030, 5000, N'Loan', 2)
SET IDENTITY_INSERT [dbo].[Loan] OFF
SET IDENTITY_INSERT [dbo].[LoanPayment] ON 

INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369381, 7, 1248)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369382, 8, 1248)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369383, 9, 1248)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369384, 10, 1248)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369385, 7, 1249)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369386, 9, 1249)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369387, 10, 1249)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369388, 7, 1251)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369389, 9, 1251)
INSERT [dbo].[LoanPayment] ([LoanPaymentID], [LoanID], [PayrollDetailID]) VALUES (3369390, 10, 1251)
SET IDENTITY_INSERT [dbo].[LoanPayment] OFF
SET IDENTITY_INSERT [dbo].[Payroll] ON 

INSERT [dbo].[Payroll] ([PayrollID], [StartDate], [EndDate], [PayrollGroupID], [DateCreated]) VALUES (1135, CAST(N'2019-09-03T00:00:00.000' AS DateTime), CAST(N'2019-09-10T00:00:00.000' AS DateTime), 7, CAST(N'2019-09-06T00:00:00.000' AS DateTime))
INSERT [dbo].[Payroll] ([PayrollID], [StartDate], [EndDate], [PayrollGroupID], [DateCreated]) VALUES (1136, CAST(N'2019-09-06T00:00:00.000' AS DateTime), CAST(N'2019-09-13T00:00:00.000' AS DateTime), 7, CAST(N'2019-09-06T00:00:00.000' AS DateTime))
INSERT [dbo].[Payroll] ([PayrollID], [StartDate], [EndDate], [PayrollGroupID], [DateCreated]) VALUES (1137, CAST(N'2019-09-06T00:00:00.000' AS DateTime), CAST(N'2019-09-13T00:00:00.000' AS DateTime), 7, CAST(N'2019-09-06T00:00:00.000' AS DateTime))
SET IDENTITY_INSERT [dbo].[Payroll] OFF
SET IDENTITY_INSERT [dbo].[PayrollDetail] ON 

INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1248, 1135, 1028)
INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1249, 1136, 1028)
INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1250, 1136, 1029)
INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1251, 1137, 1028)
INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1252, 1137, 1029)
INSERT [dbo].[PayrollDetail] ([PayrollDetailID], [PayrollID], [EmployeeID]) VALUES (1253, 1137, 1030)
SET IDENTITY_INSERT [dbo].[PayrollDetail] OFF
SET IDENTITY_INSERT [dbo].[PayrollGroup] ON 

INSERT [dbo].[PayrollGroup] ([PayrollGroupID], [Name]) VALUES (2, N'Yearly Group')
INSERT [dbo].[PayrollGroup] ([PayrollGroupID], [Name]) VALUES (5, N'Everyone')
INSERT [dbo].[PayrollGroup] ([PayrollGroupID], [Name]) VALUES (6, N'Monthly Group')
INSERT [dbo].[PayrollGroup] ([PayrollGroupID], [Name]) VALUES (7, N'Weekly Group')
SET IDENTITY_INSERT [dbo].[PayrollGroup] OFF
SET IDENTITY_INSERT [dbo].[Users] ON 

INSERT [dbo].[Users] ([UserId], [FullName], [Username], [Password], [SecretQuestion], [SecretAnswer]) VALUES (4, N'Neil', N'mras', N'', N'who are you?', N'1234')
SET IDENTITY_INSERT [dbo].[Users] OFF
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_IsPhilhealthActive]  DEFAULT ((0)) FOR [IsPhilhealthActive]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_IsSSSActive]  DEFAULT ((0)) FOR [IsSSSActive]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_IsIncomeTaxActive]  DEFAULT ((0)) FOR [IsIncomeTaxActive]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_IsPagibigActive]  DEFAULT ((0)) FOR [IsPagibigActive]
GO
ALTER TABLE [dbo].[Attendance]  WITH CHECK ADD  CONSTRAINT [FK__Attendanc__Payro__08012052] FOREIGN KEY([PayrollDetailsID])
REFERENCES [dbo].[PayrollDetail] ([PayrollDetailID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Attendance] CHECK CONSTRAINT [FK__Attendanc__Payro__08012052]
GO
ALTER TABLE [dbo].[Contribution]  WITH CHECK ADD FOREIGN KEY([ContributionTypeID])
REFERENCES [dbo].[ContributionType] ([ContributionTypeID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Contribution]  WITH CHECK ADD  CONSTRAINT [FK__Contribut__Payro__1A1FD08D] FOREIGN KEY([PayrollDetailID])
REFERENCES [dbo].[PayrollDetail] ([PayrollDetailID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Contribution] CHECK CONSTRAINT [FK__Contribut__Payro__1A1FD08D]
GO
ALTER TABLE [dbo].[Deduction]  WITH CHECK ADD FOREIGN KEY([DeductionTypeID])
REFERENCES [dbo].[DeductionsTypes] ([DeductionTypeID])
GO
ALTER TABLE [dbo].[Deduction]  WITH CHECK ADD  CONSTRAINT [FK_Deduction_Attendance] FOREIGN KEY([AttendanceID])
REFERENCES [dbo].[Attendance] ([AttendanceID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Deduction] CHECK CONSTRAINT [FK_Deduction_Attendance]
GO
ALTER TABLE [dbo].[Employee]  WITH CHECK ADD  CONSTRAINT [FK__Employee__Employ__226010D3] FOREIGN KEY([EmployeeTypeID])
REFERENCES [dbo].[EmployeeType] ([EmployeeTypeID])
GO
ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK__Employee__Employ__226010D3]
GO
ALTER TABLE [dbo].[Employee]  WITH CHECK ADD  CONSTRAINT [FK__Employee__Employ__52442E1F] FOREIGN KEY([EmployeeGroupID])
REFERENCES [dbo].[PayrollGroup] ([PayrollGroupID])
GO
ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK__Employee__Employ__52442E1F]
GO
ALTER TABLE [dbo].[Leave]  WITH CHECK ADD  CONSTRAINT [FK__Leave__EmployeeI__3AA1AEB8] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[Leave] CHECK CONSTRAINT [FK__Leave__EmployeeI__3AA1AEB8]
GO
ALTER TABLE [dbo].[Loan]  WITH CHECK ADD  CONSTRAINT [FK__Loan__EmployeeID__3F865F66] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[Loan] CHECK CONSTRAINT [FK__Loan__EmployeeID__3F865F66]
GO
ALTER TABLE [dbo].[LoanPayment]  WITH CHECK ADD  CONSTRAINT [FK__LoanPayme__LoanI__4356F04A] FOREIGN KEY([LoanID])
REFERENCES [dbo].[Loan] ([LoanID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPayment] CHECK CONSTRAINT [FK__LoanPayme__LoanI__4356F04A]
GO
ALTER TABLE [dbo].[LoanPayment]  WITH CHECK ADD  CONSTRAINT [FK__LoanPayme__Payro__444B1483] FOREIGN KEY([PayrollDetailID])
REFERENCES [dbo].[PayrollDetail] ([PayrollDetailID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPayment] CHECK CONSTRAINT [FK__LoanPayme__Payro__444B1483]
GO
ALTER TABLE [dbo].[Payroll]  WITH CHECK ADD FOREIGN KEY([PayrollGroupID])
REFERENCES [dbo].[PayrollGroup] ([PayrollGroupID])
GO
ALTER TABLE [dbo].[PayrollDetail]  WITH CHECK ADD  CONSTRAINT [FK__PayrollDe__Emplo__07E124C1] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayrollDetail] CHECK CONSTRAINT [FK__PayrollDe__Emplo__07E124C1]
GO
ALTER TABLE [dbo].[PayrollDetail]  WITH CHECK ADD  CONSTRAINT [FK__PayrollDe__Payro__2E26C93A] FOREIGN KEY([PayrollID])
REFERENCES [dbo].[Payroll] ([PayrollID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayrollDetail] CHECK CONSTRAINT [FK__PayrollDe__Payro__2E26C93A]
GO
/****** Object:  StoredProcedure [dbo].[sp_addLoanPayment]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_addLoanPayment](
@PayrollDetailID int)
as
declare @EmployeeID as int = (select EmployeeID from PayrollDetail where PayrollDetailID=@PayrollDetailID)

declare activeLoans cursor for select LoanID from Loan where EmployeeID = @EmployeeID and IsPaid = 0;
declare @LoanID as int;
open activeLoans
fetch next from activeLoans into @LoanID
while @@FETCH_STATUS = 0
begin
if(ISNULL(@LoanID,0)!=0) 
insert into LoanPayment(PayrollDetailID,LoanID) values(@payrollDetailID,@LoanID)
end
close activeLoans
deallocate activeLoans
GO
/****** Object:  StoredProcedure [dbo].[sp_updateEmployee]    Script Date: 9/9/2019 8:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_updateEmployee]
@fname varchar(50),
@lname varchar(50),
@mname varchar(50),
@dob datetime,
@age int,
@contact varchar(50),
@address varchar(50),
@gender varchar(50),
@availableLeaves varchar(50),
@pagibig varchar(50),
@sss varchar(50),
@philhealth varchar(50),
@tin varchar(50),
@branch varchar(50),
@empId int,
@status varchar(50)
as
update Employees
set FirstName = @fname, LastName = @lname, MiddleName = @mname, DateOfBirth = @dob, Age = @age , ContactNumber = @contact, Address = @address, Gender = @gender, AvailableLeaves = @availableLeaves, PagIbigID = @pagibig, SSSID = @sss, PhilhealthID = @philhealth, TINID = @tin, Status = @status where EmployeeID = @empId 
GO
USE [master]
GO
ALTER DATABASE [CJLSFOODSPAYROLL] SET  READ_WRITE 
GO
