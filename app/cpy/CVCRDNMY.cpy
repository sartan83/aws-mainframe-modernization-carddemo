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
      * Work area for card number normalization. Card numbers are held
      * as 17 digits, right justified and zero padded on the left, so a
      * legacy 16 digit card number is stored as '0' + the 16 digits.
      * Used together with the CSNRMCDY procedure copybook.
      ******************************************************************
       01  WS-CARDNUM-NORM-AREA.
           05  WS-CARDNUM-NORM-IN                  PIC X(17).
           05  WS-CARDNUM-NORM-IN-R REDEFINES
               WS-CARDNUM-NORM-IN.
               10  WS-CARDNUM-NORM-CHAR            PIC X(01)
                                                   OCCURS 17 TIMES.
           05  WS-CARDNUM-NORM-OUT                 PIC X(17).
           05  WS-CARDNUM-NORM-IDX                 PIC S9(04) COMP.
           05  WS-CARDNUM-NORM-FIRST               PIC S9(04) COMP.
           05  WS-CARDNUM-NORM-LAST                PIC S9(04) COMP.
           05  WS-CARDNUM-NORM-LEN                 PIC S9(04) COMP.
