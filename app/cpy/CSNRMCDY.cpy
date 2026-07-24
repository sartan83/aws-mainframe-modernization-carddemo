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
       Z100-NORMALIZE-CARDNUM.
      *****************************************************************
      * Normalize WS-CARDNUM-NORM-IN into WS-CARDNUM-NORM-OUT as a 17
      * digit card number, right justified and zero padded on the left.
      * A 16 digit card number becomes '0' + the 16 digits, which keeps
      * legacy card numbers valid. Requires copybook CVCRDNMY.
      *****************************************************************
           INSPECT WS-CARDNUM-NORM-IN
                   REPLACING ALL LOW-VALUE BY SPACE

           MOVE WS-CARDNUM-NORM-IN       TO WS-CARDNUM-NORM-OUT
           MOVE ZERO                     TO WS-CARDNUM-NORM-FIRST
                                            WS-CARDNUM-NORM-LAST

           PERFORM VARYING WS-CARDNUM-NORM-IDX FROM 1 BY 1
                   UNTIL WS-CARDNUM-NORM-IDX > 17
              IF WS-CARDNUM-NORM-CHAR(WS-CARDNUM-NORM-IDX)
                 NOT EQUAL SPACE
                 IF WS-CARDNUM-NORM-FIRST EQUAL ZERO
                    MOVE WS-CARDNUM-NORM-IDX
                                         TO WS-CARDNUM-NORM-FIRST
                 END-IF
                 MOVE WS-CARDNUM-NORM-IDX
                                         TO WS-CARDNUM-NORM-LAST
              END-IF
           END-PERFORM

           IF WS-CARDNUM-NORM-FIRST GREATER THAN ZERO
              COMPUTE WS-CARDNUM-NORM-LEN = WS-CARDNUM-NORM-LAST
                                          - WS-CARDNUM-NORM-FIRST + 1
              MOVE ALL '0'               TO WS-CARDNUM-NORM-OUT
              MOVE WS-CARDNUM-NORM-IN
                   (WS-CARDNUM-NORM-FIRST:WS-CARDNUM-NORM-LEN)
                TO WS-CARDNUM-NORM-OUT
                   (18 - WS-CARDNUM-NORM-LEN:WS-CARDNUM-NORM-LEN)
           END-IF
           .

       Z100-NORMALIZE-CARDNUM-EXIT.
           EXIT
           .
