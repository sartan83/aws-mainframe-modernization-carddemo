//CBCRDCVT JOB 'Convert card number to 17 digits',CLASS=A,MSGCLASS=0,
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
//* ONE TIME MIGRATION OF THE CARD NUMBER FROM 16 TO 17 DIGITS.
//* LEGACY 16 DIGIT CARD NUMBERS BECOME '0' + 16 DIGITS AND THE
//* TRAILING FILLER OF EACH RECORD SHRINKS BY ONE BYTE, SO THE
//* RECORD LENGTHS STAY AT 150 (CARDDAT), 50 (CARDXREF) AND
//* 350 (TRANSACT). RUN THIS JOB ONCE, AFTER THE NEW LOAD MODULES
//* HAVE BEEN INSTALLED.
//*********************************************************************
//* Close files in CICS region
//*********************************************************************
//CLCIFIL EXEC PGM=SDSF
//ISFOUT DD SYSOUT=*
//CMDOUT DD SYSOUT=*
//ISFIN  DD *
 /F CICSAWSA,'CEMT SET FIL(CARDDAT ) CLO'
 /F CICSAWSA,'CEMT SET FIL(CARDAIX ) CLO'
 /F CICSAWSA,'CEMT SET FIL(CXACAIX ) CLO'
 /F CICSAWSA,'CEMT SET FIL(CARDXREF) CLO'
 /F CICSAWSA,'CEMT SET FIL(TRANSACT) CLO'
/*
//* *******************************************************************
//* UNLOAD THE LEGACY VSAM FILES TO SEQUENTIAL DATASETS
//* *******************************************************************
//STEP05 EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//CARDVSAM DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS
//CARDSEQ  DD DSN=AWS.M2.CARDDEMO.CARDDATA.LGCY16.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(1,1),RLSE),
//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//XREFVSAM DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS
//XREFSEQ  DD DSN=AWS.M2.CARDDEMO.CARDXREF.LGCY16.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(1,1),RLSE),
//         DCB=(RECFM=FB,LRECL=50,BLKSIZE=0)
//TRANVSAM DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
//TRANSEQ  DD DSN=AWS.M2.CARDDEMO.TRANSACT.LGCY16.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,1),RLSE),
//         DCB=(RECFM=FB,LRECL=350,BLKSIZE=0)
//SYSIN    DD   *
   REPRO INFILE(CARDVSAM) OUTFILE(CARDSEQ)
   REPRO INFILE(XREFVSAM) OUTFILE(XREFSEQ)
   REPRO INFILE(TRANVSAM) OUTFILE(TRANSEQ)
/*
//* *******************************************************************
//* CONVERT THE CARD NUMBER TO 17 DIGITS
//* *******************************************************************
//STEP10 EXEC PGM=CBCRDCVT
//STEPLIB  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.LOADLIB
//LGCYCARD DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.LGCY16.PS
//LGCYXREF DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.LGCY16.PS
//LGCYTRAN DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.LGCY16.PS
//NEWCARD  DD DSN=AWS.M2.CARDDEMO.CARDDATA.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(1,1),RLSE),
//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//NEWXREF  DD DSN=AWS.M2.CARDDEMO.CARDXREF.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(1,1),RLSE),
//         DCB=(RECFM=FB,LRECL=50,BLKSIZE=0)
//NEWTRAN  DD DSN=AWS.M2.CARDDEMO.TRANSACT.NEW17.PS,
//         DISP=(NEW,CATLG,DELETE),
//         UNIT=SYSDA,
//         SPACE=(CYL,(5,1),RLSE),
//         DCB=(RECFM=FB,LRECL=350,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//* *******************************************************************
//* RECREATE THE CARD AND XREF CLUSTERS WITH A 17 BYTE KEY AND THE
//* TRANSACTION CLUSTER WITH THE SHIFTED CARD NUMBER ALTERNATE INDEX
//* *******************************************************************
//STEP15 EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
   DELETE AWS.M2.CARDDEMO.CARDDATA.VSAM.AIX ALTERNATEINDEX
   IF MAXCC LE 08 THEN SET MAXCC = 0
   DELETE AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS CLUSTER
   IF MAXCC LE 08 THEN SET MAXCC = 0
   DELETE AWS.M2.CARDDEMO.CARDXREF.VSAM.AIX ALTERNATEINDEX
   IF MAXCC LE 08 THEN SET MAXCC = 0
   DELETE AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS CLUSTER
   IF MAXCC LE 08 THEN SET MAXCC = 0
   DELETE AWS.M2.CARDDEMO.TRANSACT.VSAM.AIX ALTERNATEINDEX
   IF MAXCC LE 08 THEN SET MAXCC = 0
   DELETE AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS CLUSTER
   IF MAXCC LE 08 THEN SET MAXCC = 0
/*
//*
//* *******************************************************************
//* THE CLUSTERS, ALTERNATE INDEXES AND PATHS ARE REDEFINED AND
//* RELOADED BY THE STANDARD DEFINE JOBS, WHICH NOW CARRY THE NEW
//* KEY LENGTHS AND OFFSETS:
//*    CARDFILE.jcl  KEYS(17 0)   AIX KEYS(11 17)
//*    XREFFILE.jcl  KEYS(17 0)   AIX KEYS(11,26)
//*    TRANFILE.jcl  KEYS(16 0)   AIX KEYS(26 305)
//* THE CONVERTED SEQUENTIAL FILES CREATED ABOVE ARE THE INPUT THEY
//* REPRO FROM, EXCEPT FOR THE TRANSACTION MASTER WHICH IS LOADED
//* FROM AWS.M2.CARDDEMO.TRANSACT.NEW17.PS
//* *******************************************************************
//*
//* Ver: CardDemo_v2.0 - 17 digit card number migration
//*
