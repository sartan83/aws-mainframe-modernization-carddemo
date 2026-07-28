       IDENTIFICATION DIVISION.
       PROGRAM-ID.    CBCRDCVT.
       AUTHOR.        CARDDEMO TEAM.
      ******************************************************************
      * Program     : CBCRDCVT.CBL
      * Application : CardDemo
      * Type        : BATCH COBOL Program
      * Function    : One time conversion of the card number from 16 to
      *               17 digits. Reads sequential unloads of the legacy
      *               CARDDAT, CARDXREF and TRANSACT files and writes
      *               new format records where the card number is a
      *               left zero padded 17 digit value ('0' + 16 digits)
      *               and the trailing FILLER is one byte shorter, so
      *               the record lengths stay at 150 / 50 / 350.
      ******************************************************************
      * Copyright Amazon.com, Inc. or its affiliates.
      * All Rights Reserved.
      *
      * Licensed under the Apache License, Version 2.0 (the "License").
      * You may not use this file except in compliance with the License.
      * You may obtain a copy of the License at
      *
      *    http://www.apache.org/licenses/LICENSE-2.0
      *
      * Unless required by applicable law or agreed to in writing,
      * software distributed under the License is distributed on an
      * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
      * either express or implied. See the License for the specific
      * language governing permissions and limitations under the License
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LGCYCARD-FILE ASSIGN TO LGCYCARD
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS LGCYCARD-STATUS.

           SELECT NEWCARD-FILE  ASSIGN TO NEWCARD
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS NEWCARD-STATUS.

           SELECT LGCYXREF-FILE ASSIGN TO LGCYXREF
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS LGCYXREF-STATUS.

           SELECT NEWXREF-FILE  ASSIGN TO NEWXREF
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS NEWXREF-STATUS.

           SELECT LGCYTRAN-FILE ASSIGN TO LGCYTRAN
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS LGCYTRAN-STATUS.

           SELECT NEWTRAN-FILE  ASSIGN TO NEWTRAN
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS  IS NEWTRAN-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  LGCYCARD-FILE.
       01  FD-LGCYCARD-REC                       PIC X(150).

       FD  NEWCARD-FILE.
       01  FD-NEWCARD-REC                        PIC X(150).

       FD  LGCYXREF-FILE.
       01  FD-LGCYXREF-REC                       PIC X(50).

       FD  NEWXREF-FILE.
       01  FD-NEWXREF-REC                        PIC X(50).

       FD  LGCYTRAN-FILE.
       01  FD-LGCYTRAN-REC                       PIC X(350).

       FD  NEWTRAN-FILE.
       01  FD-NEWTRAN-REC                        PIC X(350).

       WORKING-STORAGE SECTION.
      ******************************************************************
      *    Legacy (16 digit card number) record layouts
      ******************************************************************
       01  LEGACY-CARD-RECORD.
           05  LGCY-CARD-NUM                     PIC X(16).
           05  LGCY-CARD-REST                    PIC X(133).
           05  LGCY-CARD-DROPPED                 PIC X(01).

       01  LEGACY-XREF-RECORD.
           05  LGCY-XREF-CARD-NUM                PIC X(16).
           05  LGCY-XREF-REST                    PIC X(33).
           05  LGCY-XREF-DROPPED                 PIC X(01).

       01  LEGACY-TRAN-RECORD.
           05  LGCY-TRAN-HEAD                    PIC X(262).
           05  LGCY-TRAN-CARD-NUM                PIC X(16).
           05  LGCY-TRAN-REST                    PIC X(71).
           05  LGCY-TRAN-DROPPED                 PIC X(01).

      ******************************************************************
      *    New (17 digit card number) record layouts
      ******************************************************************
       01  NEW-CARD-RECORD.
           05  NEW-CARD-NUM                      PIC X(17).
           05  NEW-CARD-REST                     PIC X(133).

       01  NEW-XREF-RECORD.
           05  NEW-XREF-CARD-NUM                 PIC X(17).
           05  NEW-XREF-REST                     PIC X(33).

       01  NEW-TRAN-RECORD.
           05  NEW-TRAN-HEAD                     PIC X(262).
           05  NEW-TRAN-CARD-NUM                 PIC X(17).
           05  NEW-TRAN-REST                     PIC X(71).

      ******************************************************************
      *    Card number normalization work area
      ******************************************************************
       COPY CVCRDNRM.

       01  FILE-STATUSES.
           05  LGCYCARD-STATUS                   PIC X(02).
               88  LGCYCARD-EOF                  VALUE '10'.
               88  LGCYCARD-OK                   VALUE '00'.
           05  NEWCARD-STATUS                    PIC X(02).
               88  NEWCARD-OK                    VALUE '00'.
           05  LGCYXREF-STATUS                   PIC X(02).
               88  LGCYXREF-EOF                  VALUE '10'.
               88  LGCYXREF-OK                   VALUE '00'.
           05  NEWXREF-STATUS                    PIC X(02).
               88  NEWXREF-OK                    VALUE '00'.
           05  LGCYTRAN-STATUS                   PIC X(02).
               88  LGCYTRAN-EOF                  VALUE '10'.
               88  LGCYTRAN-OK                   VALUE '00'.
           05  NEWTRAN-STATUS                    PIC X(02).
               88  NEWTRAN-OK                    VALUE '00'.

       01  WS-COUNTERS.
           05  WS-CARD-READ                      PIC 9(09) VALUE 0.
           05  WS-CARD-WRITTEN                   PIC 9(09) VALUE 0.
           05  WS-XREF-READ                      PIC 9(09) VALUE 0.
           05  WS-XREF-WRITTEN                   PIC 9(09) VALUE 0.
           05  WS-TRAN-READ                      PIC 9(09) VALUE 0.
           05  WS-TRAN-WRITTEN                   PIC 9(09) VALUE 0.
           05  WS-DATA-LOSS                      PIC 9(09) VALUE 0.

       01  WS-RETURN-CODE                        PIC S9(04) COMP
                                                 VALUE 0.
      *
       PROCEDURE DIVISION.
       0000-MAIN.

           DISPLAY 'CBCRDCVT: CARD NUMBER 16 TO 17 DIGIT CONVERSION'

           PERFORM 1000-CONVERT-CARDS
           PERFORM 2000-CONVERT-XREFS
           PERFORM 3000-CONVERT-TRANS

           DISPLAY 'CBCRDCVT: CARD  RECORDS READ    : ' WS-CARD-READ
           DISPLAY 'CBCRDCVT: CARD  RECORDS WRITTEN : ' WS-CARD-WRITTEN
           DISPLAY 'CBCRDCVT: XREF  RECORDS READ    : ' WS-XREF-READ
           DISPLAY 'CBCRDCVT: XREF  RECORDS WRITTEN : ' WS-XREF-WRITTEN
           DISPLAY 'CBCRDCVT: TRAN  RECORDS READ    : ' WS-TRAN-READ
           DISPLAY 'CBCRDCVT: TRAN  RECORDS WRITTEN : ' WS-TRAN-WRITTEN

           IF WS-DATA-LOSS > 0
              DISPLAY 'CBCRDCVT: WARNING - NON BLANK FILLER TRUNCATED '
                      'ON ' WS-DATA-LOSS ' RECORD(S)'
              MOVE 4 TO WS-RETURN-CODE
           END-IF

           MOVE WS-RETURN-CODE TO RETURN-CODE
           GOBACK
           .
      ******************************************************************
      *    CARDDAT conversion
      ******************************************************************
       1000-CONVERT-CARDS.

           OPEN INPUT  LGCYCARD-FILE
           IF NOT LGCYCARD-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN LGCYCARD, STATUS: '
                      LGCYCARD-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           OPEN OUTPUT NEWCARD-FILE
           IF NOT NEWCARD-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN NEWCARD, STATUS: '
                      NEWCARD-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           PERFORM UNTIL LGCYCARD-EOF
              READ LGCYCARD-FILE INTO LEGACY-CARD-RECORD
              IF LGCYCARD-OK
                 ADD 1 TO WS-CARD-READ
                 PERFORM 1100-CHECK-DROPPED-CARD
                 MOVE LGCY-CARD-NUM     TO WS-CN-VALUE
                 PERFORM CARDNUM-NORMALIZE
                    THRU CARDNUM-NORMALIZE-EXIT
                 MOVE WS-CN-VALUE       TO NEW-CARD-NUM
                 MOVE LGCY-CARD-REST    TO NEW-CARD-REST
                 WRITE FD-NEWCARD-REC FROM NEW-CARD-RECORD
                 ADD 1 TO WS-CARD-WRITTEN
              END-IF
           END-PERFORM

           CLOSE LGCYCARD-FILE
                 NEWCARD-FILE
           .

       1100-CHECK-DROPPED-CARD.
           IF LGCY-CARD-DROPPED NOT = SPACE
           AND LGCY-CARD-DROPPED NOT = LOW-VALUES
              ADD 1 TO WS-DATA-LOSS
              DISPLAY 'CBCRDCVT: CARD ' LGCY-CARD-NUM
                      ' HAD DATA IN THE TRUNCATED FILLER BYTE'
           END-IF
           .
      ******************************************************************
      *    CARDXREF conversion
      ******************************************************************
       2000-CONVERT-XREFS.

           OPEN INPUT  LGCYXREF-FILE
           IF NOT LGCYXREF-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN LGCYXREF, STATUS: '
                      LGCYXREF-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           OPEN OUTPUT NEWXREF-FILE
           IF NOT NEWXREF-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN NEWXREF, STATUS: '
                      NEWXREF-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           PERFORM UNTIL LGCYXREF-EOF
              READ LGCYXREF-FILE INTO LEGACY-XREF-RECORD
              IF LGCYXREF-OK
                 ADD 1 TO WS-XREF-READ
                 IF LGCY-XREF-DROPPED NOT = SPACE
                 AND LGCY-XREF-DROPPED NOT = LOW-VALUES
                    ADD 1 TO WS-DATA-LOSS
                    DISPLAY 'CBCRDCVT: XREF ' LGCY-XREF-CARD-NUM
                            ' HAD DATA IN THE TRUNCATED FILLER BYTE'
                 END-IF
                 MOVE LGCY-XREF-CARD-NUM TO WS-CN-VALUE
                 PERFORM CARDNUM-NORMALIZE
                    THRU CARDNUM-NORMALIZE-EXIT
                 MOVE WS-CN-VALUE        TO NEW-XREF-CARD-NUM
                 MOVE LGCY-XREF-REST     TO NEW-XREF-REST
                 WRITE FD-NEWXREF-REC FROM NEW-XREF-RECORD
                 ADD 1 TO WS-XREF-WRITTEN
              END-IF
           END-PERFORM

           CLOSE LGCYXREF-FILE
                 NEWXREF-FILE
           .
      ******************************************************************
      *    TRANSACT conversion
      ******************************************************************
       3000-CONVERT-TRANS.

           OPEN INPUT  LGCYTRAN-FILE
           IF NOT LGCYTRAN-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN LGCYTRAN, STATUS: '
                      LGCYTRAN-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           OPEN OUTPUT NEWTRAN-FILE
           IF NOT NEWTRAN-OK
              DISPLAY 'CBCRDCVT: CANNOT OPEN NEWTRAN, STATUS: '
                      NEWTRAN-STATUS
              MOVE 12 TO WS-RETURN-CODE
              MOVE WS-RETURN-CODE TO RETURN-CODE
              GOBACK
           END-IF

           PERFORM UNTIL LGCYTRAN-EOF
              READ LGCYTRAN-FILE INTO LEGACY-TRAN-RECORD
              IF LGCYTRAN-OK
                 ADD 1 TO WS-TRAN-READ
                 IF LGCY-TRAN-DROPPED NOT = SPACE
                 AND LGCY-TRAN-DROPPED NOT = LOW-VALUES
                    ADD 1 TO WS-DATA-LOSS
                    DISPLAY 'CBCRDCVT: TRAN ' LGCY-TRAN-HEAD(1:16)
                            ' HAD DATA IN THE TRUNCATED FILLER BYTE'
                 END-IF
                 MOVE LGCY-TRAN-CARD-NUM TO WS-CN-VALUE
                 PERFORM CARDNUM-NORMALIZE
                    THRU CARDNUM-NORMALIZE-EXIT
                 MOVE LGCY-TRAN-HEAD     TO NEW-TRAN-HEAD
                 MOVE WS-CN-VALUE        TO NEW-TRAN-CARD-NUM
                 MOVE LGCY-TRAN-REST     TO NEW-TRAN-REST
                 WRITE FD-NEWTRAN-REC FROM NEW-TRAN-RECORD
                 ADD 1 TO WS-TRAN-WRITTEN
              END-IF
           END-PERFORM

           CLOSE LGCYTRAN-FILE
                 NEWTRAN-FILE
           .
      ******************************************************************
      *    Common code to normalize a card number to 17 digits
      ******************************************************************
       COPY CVCRDNRP.
