//MIGCRD17 JOB 'MIG CARD 17',CLASS=A,MSGCLASS=0,
// NOTIFY=&SYSUID
//******************************************************************
//* Copyright Amazon.com, Inc. or its affiliates.
//* All Rights Reserved.
//*
//* Licensed under the Apache License, Version 2.0 (the "License").
//* You may not use this file except in compliance with the License.
//* You may obtain a copy of the License at
//*
//*    http://www.apache.org/licenses/LICENSE-2.0
//*
//* Unless required by applicable law or agreed to in writing,
//* software distributed under the License is distributed on an
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//* either express or implied. See the License for the specific
//* language governing permissions and limitations under the License
//******************************************************************
//* *******************************************************************
//* ONE TIME MIGRATION OF THE CARD NUMBER FROM 16 TO 17 DIGITS
//*
//* EVERY EXISTING 16 DIGIT CARD NUMBER IS LEFT PADDED WITH A SINGLE
//* '0' SO THAT IT BECOMES A VALID 17 DIGIT CARD NUMBER. THE RECORD
//* LENGTHS ARE PRESERVED BY DROPPING THE LAST BYTE OF THE TRAILING
//* FILLER OF EACH RECORD LAYOUT.
//*
//* RUN THIS JOB ONCE, AFTER THE VSAM CLUSTERS HAVE BEEN REDEFINED
//* WITH THE NEW KEY LENGTHS (CARDFILE.JCL / XREFFILE.JCL /
//* TRANFILE.JCL) AND BEFORE THE APPLICATION IS RESTARTED.
//* *******************************************************************
//* *******************************************************************
//* STEP05 - UNLOAD THE CARD MASTER   (CARD-NUM     : POS 1  LEN 16)
//* *******************************************************************
//STEP05  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS
//FILEOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=150,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.CARDDATA.MIG16
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP10 - LEFT PAD THE CARD NUMBER OF THE CARD MASTER
//* *******************************************************************
//STEP10  EXEC PGM=SORT
//SORTIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.MIG16
//SORTOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=150,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.CARDDATA.MIG17
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=COPY
  OUTREC FIELDS=(1:C'0',2:1,149)
/*
//* *******************************************************************
//* STEP15 - RELOAD THE CARD MASTER (KEYS(17 0) CLUSTER)
//* *******************************************************************
//STEP15  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.MIG17
//FILEOUT  DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP20 - UNLOAD THE CARD XREF     (XREF-CARD-NUM: POS 1  LEN 16)
//* *******************************************************************
//STEP20  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS
//FILEOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=50,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.CARDXREF.MIG16
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP25 - LEFT PAD THE CARD NUMBER OF THE CARD XREF
//* *******************************************************************
//STEP25  EXEC PGM=SORT
//SORTIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.MIG16
//SORTOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=50,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.CARDXREF.MIG17
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=COPY
  OUTREC FIELDS=(1:C'0',2:1,49)
/*
//* *******************************************************************
//* STEP30 - RELOAD THE CARD XREF (KEYS(17 0) CLUSTER)
//* *******************************************************************
//STEP30  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.MIG17
//FILEOUT  DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP35 - UNLOAD THE TRANSACTIONS  (TRAN-CARD-NUM: POS 263 LEN 16)
//* *******************************************************************
//STEP35  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
//FILEOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=350,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.TRANSACT.MIG16
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP40 - LEFT PAD THE CARD NUMBER OF THE TRANSACTIONS
//* *******************************************************************
//STEP40  EXEC PGM=SORT
//SORTIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.MIG16
//SORTOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=350,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.TRANSACT.MIG17
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=COPY
  OUTREC FIELDS=(1:1,262,263:C'0',264:263,87)
/*
//* *******************************************************************
//* STEP45 - RELOAD THE TRANSACTIONS
//* *******************************************************************
//STEP45  EXEC PGM=IDCAMS
//FILEIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.MIG17
//FILEOUT  DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CTL(REPROCT)
//* *******************************************************************
//* STEP50 - LEFT PAD THE CARD NUMBER OF THE DAILY TRANSACTIONS
//* *******************************************************************
//STEP50  EXEC PGM=SORT
//SORTIN   DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.DALYTRAN.PS
//SORTOUT  DD DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         DCB=(LRECL=350,RECFM=FB,BLKSIZE=0),
//         SPACE=(CYL,(1,1),RLSE),
//         DSN=AWS.M2.CARDDEMO.DALYTRAN.MIG17
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=COPY
  OUTREC FIELDS=(1:1,262,263:C'0',264:263,87)
/*
//* *******************************************************************
//* STEP55 - WIDEN AND LEFT PAD CARD_NUM OF THE AUTHFRDS DB2 TABLE
//* *******************************************************************
//STEP55  EXEC PGM=IKJEFT01,DYNAMNBR=20
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBCG)
 RUN PROGRAM(DSNTEP2) PLAN(DSNTEP12) -
     LIB('DSNC10.RUNLIB.LOAD')
 END
/*
//SYSIN    DD *
  ALTER TABLE CARDDEMO.AUTHFRDS
        ALTER COLUMN CARD_NUM SET DATA TYPE CHAR(17);
  UPDATE CARDDEMO.AUTHFRDS
     SET CARD_NUM = '0' CONCAT STRIP(CARD_NUM)
   WHERE LENGTH(STRIP(CARD_NUM)) = 16;
  COMMIT;
/*
//*
