DROP DATABASE IF EXISTS bank;
CREATE DATABASE bank;
USE bank;
CREATE TABLE FDType (
  typeId   VARCHAR(20),
  interest INT NOT NULL,
  time     INT NOT NULL,
  PRIMARY KEY (typeId)
);
CREATE TABLE Customer (
  CustomerId   VARCHAR(20),
  Address      TEXT NOT NULL,
  PhoneNumber  VARCHAR(10),
  EmailAddress TEXT,
  CHECK (CHAR_LENGTH(PhoneNumber) = 10),
  PRIMARY KEY (CustomerId)
);

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
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
);

CREATE TABLE Organization (
  CustomerId       VARCHAR(20),
  organizationName TEXT NOT NULL,
  PRIMARY KEY (CustomerId),
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
);

#Isuru

CREATE TABLE Interest (
  accountType    VARCHAR(20) PRIMARY KEY,
  interest       DECIMAL(13, 2) NOT NULL,
  MinimumBalance DECIMAL(13, 2) NOT NULL
);


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

CREATE TABLE BranchManager (
  branchID   VARCHAR(20) PRIMARY KEY,
  employeeID VARCHAR(20) NOT NULL,
  FOREIGN KEY (employeeID) REFERENCES Employee (employeeID)
);


CREATE TABLE Account (
  AccountId      VARCHAR(20) NOT NULL,
  CustomerId     VARCHAR(20)   NOT NULL,
  branchCode     VARCHAR(20)   NOT NULL,
  AccountBalance DECIMAL(13, 2) NOT NULL,
  NomineeId      VARCHAR(20)   NOT NULL,
  PRIMARY KEY (AccountId),
  FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId),
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode),
  FOREIGN KEY (NomineeId) REFERENCES Nominee (NomineeId)
);


CREATE TABLE SavingsAccount (
  AccountId       VARCHAR(20) NOT NULL,
  noOfWithdrawals INT    NOT NULL,
  accountType     VARCHAR(20) NOT NULL,
  PRIMARY KEY (AccountId),
  FOREIGN KEY (AccountId) REFERENCES Account (AccountId),
  FOREIGN KEY (accountType) REFERENCES Interest (accountType)
);

DELIMITER $$

CREATE PROCEDURE `check_balance`(IN AccBalance FLOAT, IN AccId VARCHAR(20))
  BEGIN
    DECLARE account_type VARCHAR(20);
    DECLARE minbal FLOAT(100,4);
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
  END
$$

DELIMITER $$
CREATE TRIGGER `check_account_balance`
  BEFORE INSERT
  ON `Account`
  FOR EACH ROW
  BEGIN
    CALL check_balance(new.AccountBalance, new.AccountId);
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



CREATE TABLE Gurantor (
  nicNumber VARCHAR(10) NOT NULL,
  name      varchar(20) NOT NULL,
  address   TEXT        NOT NULL,
  phone     VARCHAR(10) NOT NULL,
  NoOfLoans INT(2),
  PRIMARY KEY (nicNumber)
);

CREATE TABLE LoanInterest (
  loanType            ENUM ("1", "2", "3"),
  interest            FLOAT NOT NULL,
  installmentDuration INT   NOT NULL,
  PRIMARY KEY (loanType)
);

CREATE TABLE LoanApplicaton (
  applicationID     INT     NOT NULL AUTO_INCREMENT,
  gurrantorID       VARCHAR(10),
  purpose           TEXT    NOT NULL,
  sourceOfFunds     TEXT    NOT NULL,
  collateralType    TEXT    NOT NULL,
  collateraNotes    TEXT    NOT NULL,
  applicationStatus BOOLEAN NOT NULL,
  customerID           VARCHAR(20)          NOT NULL,
  loanType             ENUM ("1", "2", "3") NOT NULL,
  loanAmount           DECIMAL(13, 2)        NOT NULL,
  startDate            DATE                 NOT NULL,
  endDate              DATE                 NOT NULL,
  nextInstallmentDate  DATE                 NOT NULL,
  nextInstallment      DECIMAL(13, 2)       NOT NULL,
  numberOfInstallments INT                  NOT NULL,
  PRIMARY KEY (applicationID),
  FOREIGN KEY (gurrantorID) REFERENCES Gurantor (nicNumber),
  FOREIGN KEY (customerID) REFERENCES Customer(CustomerId),
  FOREIGN KEY (loanType) REFERENCES LoanInterest(loanType)
);



# Validation for LoanInterest table
DELIMITER $$

CREATE PROCEDURE `check_LoanInterest`(IN interest FLOAT, IN installmentDuration INT)
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
  Amount          FLOAT,
  FOREIGN KEY (branchCode) REFERENCES Branch (branchCode),
  FOREIGN KEY (OfficerInCharge) REFERENCES Employee (employeeID)
);

CREATE TABLE ATMTransaction (
  TransactionID varchar(20) PRIMARY KEY,
  fromAccountID VARCHAR(20) NOT NULL,
  ATMId         VARCHAR(20) NOT NULL,
  TimeStamp     TIMESTAMP   NOT NULL,
  Amount        FLOAT,
  FOREIGN KEY (fromAccountID) REFERENCES Account (AccountId),
  FOREIGN KEY (ATMId) REFERENCES ATMInformation (ATMId)
);

CREATE TABLE Transaction (
  TransactionID varchar(20) PRIMARY KEY,
  fromAccountID VARCHAR(20) NOT NULL,
  toAccountID   VARCHAR(20) NOT NULL,
  branchCode    VARCHAR(20) NOT NULL,
  TimeStamp     TIMESTAMP   NOT NULL,
  Amount        FLOAT,
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
  passsword VARCHAR(32),
  role      ENUM ("admin", "user", "employee"),
  PRIMARY KEY (id)
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
    IF check_account_balance(old_balance, NEW.Amount) = true
    THEN
      UPDATE `Account` SET AccountBalance = (old_balance - NEW.Amount) WHERE AccountId = NEW.fromAccountID;
      UPDATE `Account` SET AccountBalance = (old_balance + NEW.Amount) WHERE AccountId = NEW.toAccountID;
    ELSE
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
    IF check_account_balance(old_balance, NEW.Amount) = true
    THEN
      UPDATE `Account` SET AccountBalance = (old_balance - NEW.Amount) WHERE AccountId = NEW.fromAccountID;
      UPDATE `Account` SET AccountBalance = (old_balance + NEW.Amount) WHERE AccountId = NEW.toAccountID;
    ELSE
      SIGNAL SQLSTATE '45002'
      SET MESSAGE_TEXT = 'Account balance is not enough to transfer';
    END IF;
  END$$
DELIMITER ;

#Insert Data
INSERT INTO `UserLogin` (`id`, `username`, `passsword`, `role`)
VALUES ('1', 'TESTOR01', MD5('0773842106'), 'user');

SELECT COUNT(*) AS 'result'
FROM UserLogin
WHERE EXISTS(SELECT passsword
             FROM UserLogin
             WHERE username = 'TESTOR01'
               AND passsword = MD5('0773842106')
               AND role = 'user');

INSERT INTO `Branch` (`branchCode`, `branchName`, `branchManagerID`)
VALUES ('BRHORANA001', 'HORANA-001', 'EMP001');

INSERT INTO `Employee` (`employeeID`, `branchCode`, `firstName`, `LastName`, `dateOfBirth`, `address`)
VALUES ('EMP001', 'BRHORANA001', 'Asela', 'Wanigasooriya', '1996-12-07', '285E, Anderson road, Horana.');

# INSERT INTO `Customer` (`CustomerId`, `Address`, `PhoneNumber`, `EmailAddress`)
# VALUES ('ABC01', 'NO:28,Colombo road,Colombo', '077384210', 'anyone@gmail.com');

INSERT INTO `Customer` (`CustomerId`, `Address`, `PhoneNumber`, `EmailAddress`)
VALUES ('ABC01', 'NO:28,Colombo road,Colombo', '0773842106', 'anyone@gmail.com');

INSERT INTO `Nominee` (`NomineeId`, `Name`, `Address`, `Phone`)
VALUES ('NOM1234', 'Nominee 1', 'Test address', '0773842108');

INSERT INTO `BranchManager` (`branchID`, `employeeID`)
VALUES ('BRHORANA001', 'EMP001');

INSERT INTO `Account` (`AccountId`, `CustomerId`, `branchCode`, `AccountBalance`, `NomineeId`)
VALUES ('ACC001', 'ABC01', 'BRHORANA001', '8000.0000', 'NOM1234');

INSERT INTO `Account` (`AccountId`, `CustomerId`, `branchCode`, `AccountBalance`, `NomineeId`)
VALUES ('ACC002', 'ABC01', 'BRHORANA001', '7000.0000', 'NOM1234');

INSERT INTO `Transaction` (`TransactionID`, `fromAccountID`, `toAccountID`, `branchCode`, `TimeStamp`, `Amount`)
VALUES ('TR001', 'ACC001', 'ACC002', 'BRHORANA001', NOW(), '8000.0000');

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Children",12,0);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
 VALUES ("Teen",11,500);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Adult",10,1000);

INSERT INTO `Interest`(`accountType`, `interest`, `MinimumBalance`)
VALUES ("Senior",13,1000);

INSERT INTO `FDType`(`typeId`, `interest`, `time`) VALUES ("FDT001",13,6), ("FDT002",14,12), ("FDT003",15,36);

CREATE VIEW branchDetailView AS
SELECT branchCode,branchName FROM Branch;

#SELECT * FROM branchDetailView;

CREATE VIEW accountDetailsView AS
SELECT AccountID,customerID,branchCode,AccountBalance,NomineeId FROM Account;

CREATE VIEW userLoginView AS
SELECT username,passsword,role FROM UserLogin;

CREATE VIEW accountTypeDetails AS
SELECT accountType FROM Interest;

CREATE VIEW pendingLoanStatus AS
SELECT applicationID, applicationStatus FROM LoanApplicaton;


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
CREATE PROCEDURE approveLoanApplication(IN _applicationID INT(11))
  BEGIN
    START TRANSACTION ;
      UPDATE pendingLoanStatus
          SET applicationStatus = 1 WHERE applicationID = _applicationID;
      INSERT INTO Loan (customerID, loanType, loanAmount, startDate, endDate, nextInstallmentDate, nextInstallment, numberOfInstallments, applicationID)
      SELECT customerID,loanType,loanAmount,startDate,endDate,nextInstallmentDate,nextInstallment,numberOfInstallments,applicationID FROM loanapplicaton;
    COMMIT ;
  END
$$
DELIMITER ;

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
      UPDATE account
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

SELECT * FROM FixedDeposit LEFT JOIN FDType T on FixedDeposit.typeId = T.typeId;

DELIMITER $$
CREATE EVENT fixedDepositInterestEvent
  ON SCHEDULE EVERY '1' DAY
  DO
    BEGIN
      START TRANSACTION ;
      UPDATE account
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

# roles and privileges
CREATE ROLE 'guest','admin','employee';

GRANT SELECT ON bank.userloginview TO 'guest';

GRANT ALL ON bank.* TO 'admin';

GRANT SELECT ON bank.* TO 'employee';
GRANT ALL ON bank.accountdetailsview TO 'employee';
GRANT ALL ON bank.pendingLoanStatus TO 'employee';