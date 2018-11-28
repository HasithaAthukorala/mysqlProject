DROP DATABASE IF EXISTS bank;
CREATE DATABASE bank;
USE bank;
CREATE TABLE FDType (
  typeId   VARCHAR(20),
  interest INT NOT NULL,
  time     INT NOT NULL,
  PRIMARY KEY (typeId)
);

-- to validate fdtype
DELIMITER $$

CREATE PROCEDURE `check_fdtypes`(IN interest DECIMAL(13,2), IN time INT)
  BEGIN
    IF interest < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Interest is incorrect!';
    end if;

    IF time < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Time is incorrect!';
    end if;
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `check_fdtypes_before_insert`
  BEFORE INSERT
  ON `FDType`
  FOR EACH ROW
  BEGIN
    CALL check_fdtypes(new.interest, new.time);
  END$$
DELIMITER ;


CREATE TABLE Customer (
  CustomerId   VARCHAR(20),
  Address      TEXT NOT NULL,
  PhoneNumber  VARCHAR(10),
  EmailAddress TEXT,
  CHECK (CHAR_LENGTH(PhoneNumber) = 10),
  CHECK (CHAR_LENGTH(PhoneNumber) = 10),
  PRIMARY KEY (CustomerId)
);

INSERT INTO Customer VALUES ("ABC02", "Matara", "0716492763", "kas@gmail.com");

DELIMITER $$
CREATE PROCEDURE `check_num`(IN phone VARCHAR(20))
  BEGIN
    IF CHAR_LENGTH(phone) != 10
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'length of the phone number must be equal to 10';
    END IF;
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_insert`
  BEFORE INSERT
  ON `Customer`
  FOR EACH ROW
  BEGIN
    CALL check_num(new.PhoneNumber);
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_update`
  BEFORE UPDATE
  ON `Customer`
  FOR EACH ROW
  BEGIN
    CALL check_num(new.PhoneNumber);
  END$$
DELIMITER ;



CREATE TABLE IndividualCustomer (
  CustomerId        VARCHAR(20),
  FirstName         TEXT                          NOT NULL,
  LastName          TEXT                          NOT NULL,
  DateOfBirth       DATE                          NOT NULL,
  EmployementStatus ENUM ('Married', 'Unmarried') NOT NULL,
  NIC               VARCHAR(12)                   NOT NULL,
  PRIMARY KEY (CustomerId),
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId) ON DELETE CASCADE
);

-- to validate birthdays
DELIMITER $$

CREATE PROCEDURE `check_birthday`(IN dob DATE)
  BEGIN
    IF dob > NOW()
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Date of Birth is incorrect!';
    end if;
  END$$
DELIMITER ;

-- validate birthday of new customer
DELIMITER $$
CREATE TRIGGER `check_birthday_before_insert`
  BEFORE INSERT
  ON `IndividualCustomer`
  FOR EACH ROW
  BEGIN
    CALL check_birthday(new.DateOfBirth);
  END$$
DELIMITER ;

CREATE TABLE Organization (
  CustomerId       VARCHAR(20),
  organizationName TEXT NOT NULL,
  PRIMARY KEY (CustomerId),
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
);



CREATE TABLE Interest (
  accountType    VARCHAR(20) PRIMARY KEY,
  interest       DECIMAL(13, 2) NOT NULL,
  MinimumBalance DECIMAL(13, 2) NOT NULL
);

-- to validate interests and minimum balances
DELIMITER $$

CREATE PROCEDURE `check_rates_balances`(IN interest DECIMAL(13,2), IN minimum_bal DECIMAL(13,2))
  BEGIN
    IF interest < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Interest is incorrect!';
    end if;

    IF minimum_bal < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Minimum balance is incorrect!';
    end if;
  END$$
DELIMITER ;

-- before insert to interest table
DELIMITER $$
CREATE TRIGGER `check_rates_minimum_balance_when_insert`
  BEFORE INSERT
  ON `Interest`
  FOR EACH ROW
  BEGIN
    CALL check_rates_balances(new.interest, new.MinimumBalance);
  END$$
DELIMITER ;


CREATE TABLE Nominee (
  NomineeId VARCHAR(20) PRIMARY KEY,
  Name      VARCHAR(20) NOT NULL,
  Address   TEXT        NOT NULL,
  Phone     VARCHAR(10) NOT NULL
);

DELIMITER $$
CREATE TRIGGER `parts_before_insert_nominee`
  BEFORE INSERT
  ON `Nominee`
  FOR EACH ROW
  BEGIN
    CALL check_num(new.Phone);
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_update_nominee`
  BEFORE UPDATE
  ON `Nominee`
  FOR EACH ROW
  BEGIN
    CALL check_num(new.Phone);
  END$$
DELIMITER ;


CREATE TABLE Branch (
  branchCode      VARCHAR(20) PRIMARY KEY,
  branchName      VARCHAR(20) NOT NULL,
  branchManagerID VARCHAR(20)
);

CREATE TABLE Employee (
  employeeID  VARCHAR(20) PRIMARY KEY,
  branchCode  VARCHAR(20) NOT NULL,
  firstName   varchar(20) NOT NULL,
  LastName    varchar(20) NOT NULL,
  dateOfBirth DATE        NOT NULL,
  address     TEXT        NOT NULL,
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode)
);


-- before insert to employee
DELIMITER $$
CREATE TRIGGER `check_employee_birthday_before_insert`
  BEFORE INSERT
  ON `Employee`
  FOR EACH ROW
  BEGIN
    CALL check_birthday(new.dateOfBirth);
  END$$
DELIMITER ;

-- before update an employee
DELIMITER $$
CREATE TRIGGER `check_employee_before_update`
  BEFORE UPDATE
  ON `Employee`
  FOR EACH ROW
  BEGIN
    CALL check_birthday(new.dateOfBirth);
  END$$
DELIMITER ;

CREATE TABLE BranchManager (
  branchID   VARCHAR(20) PRIMARY KEY,
  employeeID VARCHAR(20) NOT NULL,
  FOREIGN KEY (employeeID) REFERENCES Employee (employeeID)
);


CREATE TABLE Account (
  AccountId      VARCHAR(20) NOT NULL,
  CustomerId     VARCHAR(20)   NOT NULL,
  branchCode     VARCHAR(20)   NOT NULL,
  AccountBalance DECIMAL(13, 2) NOT NULL default 0,
  NomineeId      VARCHAR(20)   NOT NULL,
  PRIMARY KEY (AccountId),
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId),
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode),
  FOREIGN KEY (NomineeId) REFERENCES Nominee (NomineeId)
);


CREATE TABLE SavingsAccount (
  AccountId       VARCHAR(20) NOT NULL,
  noOfWithdrawals INT    NOT NULL default 0,
  accountType     VARCHAR(20) NOT NULL,
  PRIMARY KEY (AccountId),
  FOREIGN KEY (AccountId) REFERENCES Account (AccountId),
  FOREIGN KEY (accountType) REFERENCES Interest (accountType)
);

CREATE TABLE LateLoans(
  loanId INT(11) primary key ,
  customerId VARCHAR(20) NOT NULL,
  FOREIGN KEY (customerId) REFERENCES Customer(CustomerId)
);

DELIMITER $$

CREATE PROCEDURE `check_balance`(IN AccBalance DECIMAL(13,2), IN AccId VARCHAR(20))
  BEGIN
    DECLARE account_type VARCHAR(20);
    DECLARE minbal DECIMAL(13,2);
    SET account_type = (SELECT accountType from SavingsAccount  where AccountId = AccId);
    SET minbal = (SELECT MinimumBalance from Interest where accountType = account_type);
    IF AccBalance  < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on interest failed!';
    END IF;

    IF minbal > AccBalance
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Account must keep the minimal balance';
    END IF;
  END$$
DELIMITER $$

-- when updating an account balance
CREATE TRIGGER `check_account_balance_when_update`
  BEFORE UPDATE
  ON `Account`
  FOR EACH ROW
  BEGIN
    CALL check_balance(new.AccountBalance, new.AccountId);
  END$$
DELIMITER ;

DELIMITER $$

-- to validate no of withdrawals and account type
CREATE PROCEDURE `update_savings_account`(IN noOfWithdrawals INT )
  BEGIN
    IF noOfWithdrawals < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Withdrawal count should be greater than zero...!';
    END IF;
    IF noOfWithdrawals > 5
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Withdrawal limit has been exceeded...!';
    END IF;
  END$$

DELIMITER ;

-- when updating an savings account
DELIMITER $$
CREATE TRIGGER `check_savings_account_when_update`
  BEFORE UPDATE
  ON `SavingsAccount`
  FOR EACH ROW
  BEGIN
    CALL update_savings_account(new.noOfWithdrawals);
  END$$
DELIMITER ;

DELIMITER $$

-- to validate no of account type
CREATE PROCEDURE `insert_savings_account`(IN account VARCHAR(20), IN type VARCHAR(20))
  BEGIN
    DECLARE dob DATE;
    DECLARE  age INT;
    SET dob = (SELECT DateOfBirth from Account  inner join IndividualCustomer on Account.CustomerId = IndividualCustomer.CustomerId where Account.AccountId = account);
    SET age = DATEDIFF(CURDATE(),dob)/365;

    IF type = "Children"
      THEN
        IF age > 18
          THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Incorrect account type for this customer...!';
        END IF;
    END IF;

    IF type = "Teen" OR type = "Adult"
      THEN
        IF age < 18
          THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Incorrect account type for this customer...!';
        END IF;
    END IF;

    IF type = "Senior"
      THEN
        IF age < 60 OR age < 18
          THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Incorrect account type for this customer...!';
        END IF;
    END IF;
  END$$

DELIMITER ;

-- when inserting to an savings account
DELIMITER $$
CREATE TRIGGER `check_savings_account_when_insert`
  BEFORE INSERT
  ON `SavingsAccount`
  FOR EACH ROW
  BEGIN
    CALL insert_savings_account(new.AccountId, new.accountType);
  END$$
DELIMITER ;


CREATE TABLE FixedDeposit (
  FDid      VARCHAR(20)   NOT NULL,
  AccountId VARCHAR(20)   NOT NULL,
  typeId    VARCHAR(20)   NOT NULL,
  amount    DECIMAL(13, 2) NOT NULL,
  nextInterestDate DATE NOT NULL,
  PRIMARY KEY (FDid),
  FOREIGN KEY (typeId) REFERENCES FDType (typeId),
  FOREIGN KEY (AccountId) REFERENCES SavingsAccount (AccountId)    ON DELETE CASCADE
);

DELIMITER $$


-- to validate fd amount
CREATE PROCEDURE `check_fd_amount`(IN amount DECIMAL(13,2))
  BEGIN
    IF amount < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'FD amount should be greater than zero...!';
    END IF;
  END$$

DELIMITER ;

-- when inserting to a fd
DELIMITER $$
CREATE TRIGGER `check_fd_when_insert`
  BEFORE INSERT
  ON `FixedDeposit`
  FOR EACH ROW
  BEGIN
    CALL check_fd_amount(new.amount);
  END$$
DELIMITER ;


CREATE TABLE Gurantor (
  gurantoID VARCHAR(20) NOT NULL,
  NoOfLoans INT(2),
  PRIMARY KEY (gurantoID),
  FOREIGN KEY (gurantoID) REFERENCES Customer (CustomerId)
);

DELIMITER $$
CREATE TRIGGER `parts_before_update_Gurantor`
  BEFORE UPDATE
  ON `Gurantor`
  FOR EACH ROW
  BEGIN
    DECLARE count INT(2);
    SELECT NoOfLoans INTO count FROM `Gurantor` WHERE gurantoID = NEW.gurantoID;
    SET count = count + 1;
    IF count>3 THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Guranor has already guranterd for 3 loans';
    end if ;
  END$$
DELIMITER ;

CREATE TABLE LoanInterest (
  loanType            ENUM ("1", "2", "3"),
  interest            DECIMAL(13,2) NOT NULL,
  installmentDuration INT   NOT NULL,
  PRIMARY KEY (loanType)
);

INSERT INTO LoanInterest VALUES ("1",5,12);
INSERT INTO LoanInterest VALUES ("2",10,24);
INSERT INTO LoanInterest VALUES ("3",15,36);

CREATE TABLE LoanApplicaton (
  applicationID     INT                  NOT NULL AUTO_INCREMENT,
  gurrantorID       VARCHAR(20),
  purpose           TEXT                 NOT NULL,
  sourceOfFunds     TEXT                 NOT NULL,
  collateralType    TEXT                 NOT NULL,
  collateraNotes    TEXT                 NOT NULL,
  applicationStatus BOOLEAN              NOT NULL,
  customerID        VARCHAR(20)          NOT NULL,
  loanType          ENUM ("1", "2", "3") NOT NULL,
  loanAmount        DECIMAL(13, 2)       NOT NULL,
  startDate         DATE                 NOT NULL,
  endDate           DATE                 NOT NULL,
  PRIMARY KEY (applicationID),
  FOREIGN KEY (gurrantorID) REFERENCES Gurantor (gurantoID),
  FOREIGN KEY (customerID) REFERENCES Customer (CustomerId),
  FOREIGN KEY (loanType) REFERENCES LoanInterest (loanType)
);

# Validation for LoanInterest table
DELIMITER $$

CREATE PROCEDURE `check_LoanInterest`(IN interest DECIMAL(13,2), IN installmentDuration INT)
  BEGIN
    IF interest < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on interest failed!';
    END IF;
    IF installmentDuration < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on installmentDuration failed!';
    END IF;
  END$$

DELIMITER ;

DELIMITER $$
CREATE TRIGGER `LoanInterest_before_insert`
  BEFORE INSERT
  ON `LoanInterest`
  FOR EACH ROW
  BEGIN
    CALL check_LoanInterest(new.interest, new.installmentDuration);
  END$$
DELIMITER ;
-- before update
DELIMITER $$
CREATE TRIGGER `LoanInterest_before_update`
  BEFORE UPDATE
  ON `LoanInterest`
  FOR EACH ROW
  BEGIN
    CALL check_LoanInterest(new.interest, new.installmentDuration);
  END$$
DELIMITER ;

# ....................................

CREATE TABLE Loan (
  loanID               INT AUTO_INCREMENT   NOT NULL,
  customerID           VARCHAR(20)          NOT NULL,
  loanType             ENUM ("1", "2", "3") NOT NULL,
  loanAmount           DECIMAL(13, 2)        NOT NULL,
  startDate            DATE                 NOT NULL,
  endDate              DATE                 NOT NULL,
  nextInstallmentDate  DATE                 NOT NULL,
  nextInstallment      DECIMAL(13, 2)       NOT NULL,
  numberOfInstallments INT                  NOT NULL,
  applicationID        INT                  NOT NULL,
  PRIMARY KEY (loanID),
  FOREIGN KEY (loanType) REFERENCES LoanInterest (loanType),
  FOREIGN KEY (applicationID) REFERENCES LoanApplicaton (applicationID),
  FOREIGN KEY (customerID) REFERENCES Customer (CustomerId)
);

CREATE TABLE OnlineLoan (
  loanID INT,
  FDid   VARCHAR(20) NOT NULL,
  PRIMARY KEY (loanID),
  FOREIGN KEY (FDid) REFERENCES FixedDeposit (FDid)
);

-- validate online loan


# validation for Loan table
DELIMITER $$

CREATE PROCEDURE `check_Loan`(IN loanAmount DECIMAL(13, 2), IN numberOfInstallments INT, IN nextInstallment DECIMAL(13, 2))
  BEGIN
    IF loanAmount < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on loan amount failed!';
    END IF;
    IF numberOfInstallments < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on number of installments failed!';
    END IF;
    IF nextInstallment < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on next installment failed!';
    END IF;
  END$$

DELIMITER ;

DELIMITER $$
CREATE TRIGGER `Loan_before_insert`
  BEFORE INSERT
  ON `Loan`
  FOR EACH ROW
  BEGIN
    CALL check_Loan(new.loanAmount, new.numberOfInstallments, new.nextInstallment);
  END$$
DELIMITER ;
-- before update
DELIMITER $$
CREATE TRIGGER `Loan_before_update`
  BEFORE UPDATE
  ON `Loan`
  FOR EACH ROW
  BEGIN
    CALL check_Loan(new.loanAmount, new.numberOfInstallments, new.nextInstallment);
  END$$
DELIMITER ;

# .......................

CREATE TABLE LoanInstallment (
  installmentID        INT           NOT NULL AUTO_INCREMENT,
  loanID               INT,
  installmentTimeStamp TIMESTAMP     NOT NULL,
  installmentAmount    DECIMAL(13, 2) NOT NULL,
  PRIMARY KEY (installmentID),
  FOREIGN KEY (loanID) REFERENCES Loan (loanID)
);

# validation for LoanInstallment table
DELIMITER $$

CREATE PROCEDURE `check_LoanInstallment`(IN installmentAmount DECIMAL(13, 2))
  BEGIN
    IF installmentAmount < 0
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'check constraint on interest failed!';
    END IF;
  END$$

DELIMITER ;

DELIMITER $$
CREATE TRIGGER `LoanInstallment_before_insert`
  BEFORE INSERT
  ON `LoanInstallment`
  FOR EACH ROW
  BEGIN
    CALL check_LoanInstallment(new.installmentAmount);
  END$$
DELIMITER ;
-- before update
DELIMITER $$
CREATE TRIGGER `LoanInstallment_before_update`
  BEFORE UPDATE
  ON `LoanInstallment`
  FOR EACH ROW
  BEGIN
    CALL check_LoanInstallment(new.installmentAmount);
  END$$
DELIMITER ;


CREATE TABLE ATMInformation (
  ATMId           varchar(20) PRIMARY KEY,
  OfficerInCharge VARCHAR(20) NOT NULL,
  location        VARCHAR(20) NOT NULL,
  branchCode      VARCHAR(20) NOT NULL,
  Amount          DECIMAL(13,2),
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode),
  FOREIGN KEY (OfficerInCharge) REFERENCES Employee (employeeID)
);

CREATE TABLE ATMTransaction (
  TransactionID INT PRIMARY KEY AUTO_INCREMENT,
  fromAccountID VARCHAR(20) NOT NULL,
  ATMId         VARCHAR(20) NOT NULL,
  TimeStamp     TIMESTAMP   NOT NULL,
  Amount        DECIMAL(13,2),
  FOREIGN KEY (fromAccountID) REFERENCES Account (AccountId),
  FOREIGN KEY (ATMId) REFERENCES ATMInformation (ATMId)
);

CREATE TABLE Transaction (
  TransactionID INT PRIMARY KEY AUTO_INCREMENT,
  fromAccountID VARCHAR(20) NOT NULL,
  toAccountID   VARCHAR(20) NOT NULL,
  branchCode    VARCHAR(20) NOT NULL,
  TimeStamp     TIMESTAMP   NOT NULL,
  Amount        DECIMAL(13,2),
  FOREIGN KEY (fromAccountID) REFERENCES Account (AccountId),
  FOREIGN KEY (toAccountID) REFERENCES Account (AccountId),
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode)
);

CREATE TABLE ATMCard (
  cardID     varchar(20) PRIMARY KEY,
  AccountID  VARCHAR(20) NOT NULL,
  startDate  DATE        NOT NULL,
  ExpireDate DATE        NOT NULL,
  FOREIGN KEY (AccountID) REFERENCES Account (AccountId)
);

CREATE TABLE UserLogin (
  id        INT AUTO_INCREMENT,
  username  VARCHAR(255),
  CustomerId   VARCHAR(20),
  passsword VARCHAR(32),
  role      ENUM ("admin", "user", "employee"),
  PRIMARY KEY (id),
  FOREIGN KEY (CustomerId) REFERENCES Customer(CustomerId)

);

DELIMITER $$
CREATE PROCEDURE `check_password_length`(IN pass VARCHAR(32))
  BEGIN
    IF CHAR_LENGTH(pass) != 32
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'password must be in md5 format';
    END IF;
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_insert_password`
  BEFORE INSERT
  ON `UserLogin`
  FOR EACH ROW
  BEGIN
    CALL check_password_length(new.passsword);
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_update_password`
  BEFORE UPDATE
  ON `UserLogin`
  FOR EACH ROW
  BEGIN
    CALL check_password_length(new.passsword);
  END$$
DELIMITER ;


#Adding a transaction
DELIMITER $$
CREATE FUNCTION check_account_balance(old_balance DECIMAL(13, 2), transaction_amount DECIMAL(13, 2))
  RETURNS BOOLEAN
DETERMINISTIC
  BEGIN
    DECLARE remained_amount DECIMAL(13, 2);
    SET remained_amount = (old_balance - transaction_amount);

    IF remained_amount < 0
    THEN
      RETURN false;
    ELSE
      RETURN true;
    END IF;
  END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `parts_before_insert_transaction_normal`;
DROP TRIGGER IF EXISTS `parts_before_update_transaction_normal`;

DELIMITER $$
CREATE TRIGGER `parts_before_insert_transaction_normal`
  BEFORE INSERT
  ON `Transaction`
  FOR EACH ROW
  BEGIN
    DECLARE old_balance DECIMAL(13, 2);
    SELECT AccountBalance INTO old_balance FROM `Account` WHERE AccountId = NEW.fromAccountID;
    IF check_account_balance(old_balance, NEW.Amount) = false
    THEN
      SIGNAL SQLSTATE '45002'
      SET MESSAGE_TEXT = 'Account balance not enough to transfer';
    END IF;
  END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `parts_before_update_transaction_normal`
  BEFORE UPDATE
  ON `Transaction`
  FOR EACH ROW
  BEGIN
    DECLARE old_balance DECIMAL(13, 2);
    SELECT AccountBalance INTO old_balance FROM `Account` WHERE AccountId = NEW.fromAccountID;
    IF check_account_balance(old_balance, NEW.Amount) = false
    THEN
      SIGNAL SQLSTATE '45002'
      SET MESSAGE_TEXT = 'Account balance is not enough to transfer';
    END IF;
  END$$
DELIMITER ;



SELECT COUNT(*) AS 'result'
FROM UserLogin
WHERE EXISTS(SELECT passsword
             FROM UserLogin
             WHERE username = 'TESTOR01'
               AND passsword = MD5('0773842106')
               AND role = 'user');

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Children",12,0);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
 VALUES ("Teen",11,500);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Adult",10,1000);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Senior",13,1000);

INSERT INTO `FDType`(`typeId`, `interest`, `time`) VALUES ("FDT001",13,6), ("FDT002",14,12), ("FDT003",15,36);



INSERT INTO `Branch` (`branchCode`, `branchName`, `branchManagerID`)
VALUES ('BRHORANA001', 'HORANA-001', 'EMP001');

INSERT INTO `Employee` (`employeeID`, `branchCode`, `firstName`, `LastName`, `dateOfBirth`, `address`)
VALUES ('EMP001', 'BRHORANA001', 'Asela', 'Wanigasooriya', '1996-12-07', '285E, Anderson road, Horana.');

INSERT INTO `ATMInformation` (ATMId, OfficerInCharge, location, branchCode, Amount) VALUES ('ATM0001','EMP001','atmlocation1','BRHORANA001',20000);
# INSERT INTO `Customer` (`CustomerId`, `Address`, `PhoneNumber`, `EmailAddress`)
# VALUES ('ABC01', 'NO:28,Colombo road,Colombo', '077384210', 'anyone@gmail.com');


INSERT INTO `Customer` (`CustomerId`, `Address`, `PhoneNumber`, `EmailAddress`)
VALUES ('ABC01', 'NO:28,Colombo road,Colombo', '0773842106', 'anyone@gmail.com');

INSERT INTO `IndividualCustomer` (`CustomerId`, `FirstName`, `LastName`, `DateOfBirth`, `EmployementStatus`, `NIC`) VALUES ('ABC01', 'Yasaa', 'Boya', '1995-1-5', 'Unmarried', '9636549632');


INSERT INTO `Nominee` (`NomineeId`, `Name`, `Address`, `Phone`)
VALUES ('NOM1234', 'Nominee 1', 'Test address', '0773842108');

INSERT INTO `BranchManager` (`branchID`, `employeeID`)
VALUES ('BRHORANA001', 'EMP001');


INSERT INTO `Account` (`AccountId`, `CustomerId`, `branchCode`, `NomineeId`)
VALUES ('ACC001', 'ABC01', 'BRHORANA001', 'NOM1234');

INSERT INTO `SavingsAccount`(`AccountId`, `accountType`)
VALUES ('ACC001',"Adult");

BEGIN;
INSERT INTO `Account` (`AccountId`, `CustomerId`, `branchCode`, `NomineeId`)
VALUES ('ACC002', 'ABC01', 'BRHORANA001', 'NOM1234');

INSERT INTO `SavingsAccount`(`AccountId`, `accountType`)
VALUES ('ACC002',"Teen");
COMMIT;

UPDATE `Account` SET `AccountBalance`='8000.000' WHERE AccountId = "ACC001";
UPDATE `Account` SET `AccountBalance`='7000.000' WHERE AccountId = "ACC002";



# INSERT INTO `Transaction` (`TransactionID`, `fromAccountID`, `toAccountID`, `branchCode`, `TimeStamp`, `Amount`)
# VALUES ('TR003', 'ACC001', 'ACC002', 'BRHORANA001', NOW(), '4000.0000');
#
#
# INSERT INTO `Transaction` (`TransactionID`, `fromAccountID`, `toAccountID`, `branchCode`, `TimeStamp`, `Amount`)
# VALUES ('TR004', 'ACC001', 'ACC002', 'BRHORANA001', NOW(), '1000.0000');


INSERT INTO `ATMCard` (`cardID`, `AccountID`, `startDate`, `ExpireDate`) VALUES ('1234123412341234', 'ACC001', '2017-03-15', '2019-03-15');
CREATE VIEW branchDetailView AS
SELECT branchCode,branchName FROM Branch;

#SELECT * FROM branchDetailView;

CREATE VIEW accountDetailsView AS
SELECT AccountID,customerID,branchCode,AccountBalance,NomineeId FROM Account;

CREATE VIEW customerDetailView AS
SELECT CustomerId,FirstName,LastName FROM IndividualCustomer;

CREATE VIEW userLoginView AS
SELECT username,passsword,role FROM UserLogin;

CREATE VIEW accountTypeDetails AS
SELECT accountType FROM Interest;

CREATE VIEW pendingLoanStatus AS
SELECT applicationID, applicationStatus FROM LoanApplicaton;

CREATE VIEW transactionHistoryView AS
SELECT fromAccountID,toAccountID,TimeStamp,Amount ,(SELECT  CustomerId FROM account JOIN Transaction T on Account.AccountId = T.fromAccountID LIMIT 1) AS fromCustomerId ,(SELECT  CustomerId FROM account JOIN Transaction T on Account.AccountId = T.toAccountID LIMIT 1) AS toCustomerId FROM Transaction ORDER BY Transaction.TransactionID DESC ;

CREATE VIEW atmTransactionHistoryView AS
SELECT fromAccountID,TimeStamp,Amount FROM ATMTransaction;


CREATE VIEW atmDetails AS
SELECT ATMId FROM ATMInformation;

DELIMITER $$
CREATE PROCEDURE creditTransferAccounts(IN fromAccount VARCHAR(20), IN toAccount VARCHAR(20),IN branchCode VARCHAR(20),IN amount DECIMAL(13,2))
  BEGIN
    DECLARE newBalance_from DECIMAL(13,2);
    DECLARE newBalance_to DECIMAL(13,2);
    DECLARE withdrawals INT(11);
    SET withdrawals = (SELECT 	noOfWithdrawals FROM SavingsAccount WHERE AccountId = fromAccount) + 1;
    SET newBalance_from = (SELECT AccountBalance FROM Account WHERE AccountId = fromAccount) - amount;
    SET newBalance_to = (SELECT AccountBalance FROM Account WHERE AccountId = fromAccount) + amount;
    START TRANSACTION ;
      INSERT INTO Transaction(`fromAccountID`,`toAccountID`,`branchCode`,`amount`)
      VALUES (fromAccount,toAccount,branchCode,amount);
      UPDATE Account
          SET AccountBalance = newBalance_from WHERE AccountId = fromAccount;
      UPDATE Account
          SET AccountBalance = newBalance_to WHERE AccountId = toAccount;
      UPDATE SavingsAccount
            SET noOfWithdrawals = withdrawals WHERE AccountId = fromAccount;
    COMMIT;
  END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE atmWithdraw(IN fromAccount VARCHAR(20), IN atmId VARCHAR(20),IN _amount DECIMAL(13,2))
  BEGIN
    DECLARE newBalance DECIMAL(13,2);
    DECLARE atmBalance DECIMAL(13,2);
    DECLARE withdrawals INT(11);
    SELECT (AccountBalance ) INTO newBalance FROM Account WHERE AccountId = fromAccount LIMIT 1;
    SELECT (Amount ) INTO atmBalance FROM ATMInformation WHERE ATMId=atmId LIMIT 1;
    SELECT 	(noOfWithdrawals ) INTO withdrawals FROM SavingsAccount WHERE AccountId = fromAccount LIMIT 1;
    SET newBalance = newBalance - _amount;
    SET atmBalance = atmBalance - _amount;
    SET withdrawals = withdrawals + 1;
    IF atmBalance >= 0 THEN
      START TRANSACTION ;
        INSERT INTO ATMTransaction(`fromAccountID`,`ATMId`,`amount`)
        VALUES (fromAccount,atmId,_amount);
        UPDATE Account
            SET AccountBalance = newBalance WHERE AccountId = fromAccount;
        UPDATE ATMInformation
            SET Amount = atmBalance WHERE ATMId= atmId;
        UPDATE SavingsAccount
            SET noOfWithdrawals = withdrawals WHERE AccountId = fromAccount;
      COMMIT;
    ELSE
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ATM HAS INSUFFICIENT FUNDS';
    END IF ;
  END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE createSavingAccount(IN accountId VARCHAR(20),
                                    IN CustomerId VARCHAR(20),
                                    IN branchCode VARCHAR(20),
                                    IN accountBalance DECIMAL(13,2),
                                    IN NomineeId VARCHAR(20),
                                    IN accountType VARCHAR(20))
  BEGIN
    # CHECK MINIMUM BALANCE
    DECLARE minimumBlance DECIMAL(13,2);
    SELECT MinimumBalance INTO minimumBlance FROM Interest WHERE Interest.accountType = accountType;
    IF minimumBlance >= accountBalance THEN
      START TRANSACTION ;
        INSERT INTO `Account` (`AccountId`, `CustomerId`, `branchCode`, `AccountBalance`, `NomineeId`)
        VALUES (accountId,CustomerId,branchCode,accountBalance,NomineeId);
        INSERT INTO `SavingsAccount` (`AccountId`,`noOfWithdrawals`,`accountType`)
        VALUES (accountId,0,accountType);
      COMMIT ;
    ELSE
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ACCOUNT BALANCE IS LESS THAN MINIMUM BALANCE OR ACCOUNT TYPE IS INVALID';
    END IF ;
  END
 $$
DELIMITER ;

CALL createSavingAccount('ACC004','ABC01','BRHORANA001',1000.00,'NOM1234','Adult');

DELIMITER $$
 CREATE PROCEDURE createFixedDeposit(IN FDid VARCHAR(20),
                                    IN AccountId VARCHAR(20),
                                    IN typeId VARCHAR(20),
                                    IN amount DECIMAL(13,2))
  BEGIN
    DECLARE nextInterestDate DATETIME;
    SET nextInterestDate = DATE_ADD(CURDATE(), INTERVAL 30 DAY);
    IF amount > 0 THEN
      START TRANSACTION;
        INSERT INTO FixedDeposit(`FDid`,`AccountId`,`typeId`,`amount`,`nextInterestDate`)
        VALUES (FDid,AccountId,typeId,amount,nextInterestDate);
      COMMIT;
    ELSE
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'FIXED DEPOSIT AMOUNT MUST BE GREATER THAN 0';
    END IF ;
  END
$$
DELIMITER ;

CALL createFixedDeposit('FD0001','ACC004','FDT001',50000.00);

# time based events
SET GLOBAL event_scheduler = 1;

DELIMITER $$
CREATE EVENT savingAccountInterestCalculationEvent
  ON SCHEDULE EVERY '1' MONTH
  STARTS '2018-12-01 00:00:00'
  DO
    BEGIN
      START TRANSACTION ;
      UPDATE Account
        SET AccountBalance = (SELECT AccountBalance * (1 + (interest/100)) FROM SavingsAccount left join Interest on SavingsAccount.accountType = Interest.accountType where Account.AccountId = SavingsAccount.AccountId)
        WHERE AccountId IN (
            SELECT AccountId FROM SavingsAccount
            );
      UPDATE SavingsAccount
          SET noOfWithdrawals = 0;
      COMMIT ;
END
$$
DELIMITER ;

DELIMITER $$
CREATE EVENT lateLoanLoggerFlusher
  ON SCHEDULE EVERY '1' MONTH
  STARTS '2018-12-01 00:00:00'
  DO
    BEGIN
      START TRANSACTION ;
        DELETE FROM LateLoans;
      COMMIT ;
END
$$
DELIMITER ;

DELIMITER $$
CREATE EVENT lateLoanLogger
  ON SCHEDULE EVERY '1' DAY
  DO
    BEGIN
      START TRANSACTION ;
      INSERT INTO LateLoans
      SELECT loanID,customerId FROM Loan WHERE CURDATE()> nextInstallmentDate;
      COMMIT;
END
$$
DELIMITER ;

DELIMITER $$
CREATE EVENT fixedDepositInterestEvent
  ON SCHEDULE EVERY '1' DAY
  DO
    BEGIN
      START TRANSACTION ;
      UPDATE Account
        SET AccountBalance = (SELECT AccountBalance * (1 + (interest/100)) FROM FixedDeposit LEFT JOIN FDType T on FixedDeposit.typeId = T.typeId where Account.AccountId = FixedDeposit.AccountId)
        WHERE AccountId IN (
            SELECT AccountId FROM FixedDeposit WHERE nextInterestDate = CURDATE()
            );
      UPDATE FixedDeposit
          SET nextInterestDate = DATE_ADD(CURDATE(), INTERVAL 30 DAY)
          WHERE nextInterestDate = curdate();
      COMMIT ;
END
$$
DELIMITER ;


# Loan application
DELIMITER $$

CREATE FUNCTION check_acount
  (id Varchar(20))
  RETURNS boolean
  BEGIN
    DECLARE result boolean;
    DECLARE newID INT;

    SELECT COUNT(CustomerId) into newID from Customer WHERE CustomerId = id;

    IF newID > 0
    then
      SET result = TRUE;
    ELSE
      SET result = FALSE;
    end if;


    RETURN result;

  END $$

DELIMITER ;

DELIMITER $$

CREATE USER IF NOT EXISTS 'adm'@'localhost' IDENTIFIED BY 'adm';
GRANT ALL ON bank.* TO 'adm'@'localhost';

CREATE PROCEDURE update_loanCount(id VARCHAR(20))
  BEGIN
    DECLARE count INT(2);
    SELECT NoOfLoans INTO count FROM Gurantor WHERE gurantoID = id;
    SET count = count + 1;
    UPDATE Gurantor SET NoOfLoans = count WHERE gurantoID = id;
  END $$

DELIMITER ;

DELIMITER $$

CREATE FUNCTION check_gurantor
  (id Varchar(20))
  RETURNS boolean
  BEGIN
    DECLARE result boolean;
    DECLARE newID INT;

    SELECT COUNT(gurantoID) into newID from Gurantor WHERE gurantoID = id;

    IF newID > 0
    then
      SET result = TRUE;
    ELSE
      SET result = FALSE;
    end if;


    RETURN result;

  END $$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE approveLoanApplication(IN _applicationID INT(11))
  BEGIN
    START TRANSACTION ;

      UPDATE pendingLoanStatus
          SET applicationStatus = 1 WHERE applicationID = _applicationID;
      INSERT INTO Loan (customerID, loanType, loanAmount, startDate, endDate, nextInstallmentDate, nextInstallment, numberOfInstallments, applicationID)
      SELECT customerID,loanType,loanAmount,startDate,endDate,DATE_ADD(startDate, INTERVAL 30 DAY),loanAmount/CAST(DATEDIFF(endDate,startDate)/30 AS INT),CAST(DATEDIFF(endDate,startDate)/30 AS INT),applicationID FROM loanapplicaton;
    COMMIT ;
  END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE payLoanInstallment(IN _loanID INT(11))
  BEGIN
    START TRANSACTION ;
      UPDATE Loan
          SET nextInstallmentDate = DATE_ADD(nextInstallmentDate,INTERVAL 30 DAY)  WHERE loanID = _loanID;
      UPDATE Loan
          SET loanAmount = (loanAmount-nextInstallment) WHERE loanID = _loanID;
      COMMIT ;
  END
$$
DELIMITER ;


call payLoanInstallment(1);

DELIMITER $$

CREATE PROCEDURE create_loanApplication(IN gurrantorID    VARCHAR(20),
                                        IN purpose        TEXT,
                                        IN sourceOfFunds  TEXT,
                                        IN collateralType TEXT,
                                        IN collateraNotes TEXT,
                                        IN customerID     VARCHAR(20),
                                        IN loantype       ENUM ("1", "2", "3"),
                                        IN loanAmount     DECIMAL(13, 2),
                                        IN startDate      DATE,
                                        IN endDate        DATE)
  BEGIN
    DECLARE precentage 	decimal(13,2);
    DECLARE amount DECIMAL(13,2);
    IF check_acount(customerID)
    THEN
      IF check_acount(gurrantorID)
      THEN
        IF check_gurantor(gurrantorID)
        THEN
          SELECT interest INTO precentage FROM LoanInterest WHERE loanType=loantype LIMIT 1;
          SET amount = loanAmount*((precentage+100)/100);
          START TRANSACTION ;
          CALL update_loanCount(gurrantorID);
          INSERT INTO `LoanApplicaton` (`gurrantorID`,
                                        `purpose`,
                                        `sourceOfFunds`,
                                        `collateralType`,
                                        `collateraNotes`,
                                        `applicationStatus`,
                                        `customerID`,
                                        `loanType`,
                                        `loanAmount`,
                                        `startDate`,
                                        `endDate`)
          VALUES (gurrantorID,
                  purpose,
                  sourceOfFunds,
                  collateralType,
                  collateraNotes,
                  FALSE,
                  customerID,
                  loantype,
                  amount,
                  startDate,
                  endDate);
          COMMIT ;
        ELSE
          SELECT interest INTO precentage FROM LoanInterest WHERE loanType=loantype LIMIT 1;
          SET amount = loanAmount*((precentage+100)/100);
          START TRANSACTION ;
          INSERT INTO Gurantor VALUES (gurrantorID, 1);
          INSERT INTO `LoanApplicaton` (`gurrantorID`,
                                        `purpose`,
                                        `sourceOfFunds`,
                                        `collateralType`,
                                        `collateraNotes`,
                                        `applicationStatus`,
                                        `customerID`,
                                        `loanType`,
                                        `loanAmount`,
                                        `startDate`,
                                        `endDate`)
          VALUES (gurrantorID,
                  purpose,
                  sourceOfFunds,
                  collateralType,
                  collateraNotes,
                  FALSE,
                  customerID,
                  loantype,
                  amount,
                  startDate,
                  endDate);
          COMMIT ;
        end if;
      ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No such Gurantor exists';
      end if;
    ELSE
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No such Customer exists';
    END IF;
  end
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `validate_online_loan`(IN customerID VARCHAR(20),
                                        IN purpose TEXT,
                                        IN sourceOfFunds TEXT,
                                        IN collateralType TEXT,
                                        IN collateralNotes TEXT,
                                        IN loanType ENUM("1", "2", "3"),
                                        IN fd VARCHAR(20),
                                        IN loanAmount DECIMAL(13,2),
                                        IN startDate DATE,
                                        IN endDate DATE)


  BEGIN
    DECLARE FDAmount DECIMAL(13,2);
    DECLARE _loanID INT;
    DECLARE applicationID INT;
    START TRANSACTION;
      CALL create_loanApplication(customerID, purpose, sourceOfFunds, collateralType, collateralNotes, customerID, loanType, loanAmount, startDate, endDate);
      SET applicationID = (SELECT applicationID FROM LoanApplicaton ORDER BY applicationID DESC LIMIT 1);
    COMMIT;
    SET FDAmount = (SELECT amount FROM fixeddeposit WHERE AccountiD = fd);
    IF  loanAmount > FDAmount*0.6 OR loanAmount > 500000
    THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Requesting loan amount is unacceptable';
    ELSE
      START TRANSACTION ;
        CALL approveLoanApplication(applicationID);
        SET _loanID = (SELECT loanID FROM Loan ORDER BY loanID DESC LIMIT 1);
        INSERT INTO `OnlineLoan`(`loanID`, `FDid`) VALUES (_loanID,fd);
      COMMIT ;

      CALL approveLoanApplication(applicationID);


    END IF;

  END$$

CALL validate_online_loan("ABC01","sad","sdfsd","sad","sdf","1","FD0001",1000.00,"2018-11-29","2019-11-29");
CALL validate_online_loan("ABC01","sad","sdfsd","sad","sdf","1","FD0001",2000.00,"2018-11-29","2019-11-29");

DELIMITER ;


CALL create_loanApplication("ABC01","Loan","sda","asda","sadas","ABC02","1",50000.00,"2018-11-28","2019-11-28");

SELECT CAST(DATEDIFF("2019-11-28","2018-11-28")/30 AS INT);
CALL approveLoanApplication(1);


CREATE USER IF NOT EXISTS 'emp'@'localhost' IDENTIFIED BY 'emp';
GRANT SELECT ON bank.* TO 'emp'@'localhost';
GRANT EXECUTE ON bank.* TO 'emp'@'localhost';

CREATE USER IF NOT EXISTS 'guest'@'localhost' IDENTIFIED BY 'guest';
GRANT SELECT ON bank.userLoginView TO 'guest'@'localhost';

CREATE USER IF NOT EXISTS 'usr'@'localhost' IDENTIFIED BY 'usr';

GRANT SELECT ON bank.customerDetailView TO 'usr'@'localhost';
GRANT SELECT ON bank.transactionHistoryView TO 'usr'@'localhost';

GRANT SELECT ON bank.atmDetails TO 'usr'@'localhost';
GRANT SELECT ON bank.atmTransactionHistoryView TO 'usr'@'localhost';
GRANT EXECUTE ON PROCEDURE  bank.create_loanApplication TO 'usr'@'localhost';
GRANT EXECUTE ON PROCEDURE  bank.validate_online_loan TO 'usr'@'localhost';

CREATE USER IF NOT EXISTS 'adm'@'localhost' IDENTIFIED BY 'adm';
GRANT ALL ON bank.* TO 'adm'@'localhost';