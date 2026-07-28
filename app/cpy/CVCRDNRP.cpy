      ******************************************************************
      * Normalize WS-CN-VALUE into a 17 digit card number.
      * A legacy 16 digit value, whether left justified (trailing space
      * or low-value) or right justified (leading space or low-value),
      * becomes '0' followed by the 16 digits. Values that are already
      * 17 bytes long are left untouched.
      ******************************************************************
       CARDNUM-NORMALIZE.

           IF WS-CN-VALUE = SPACES
           OR WS-CN-VALUE = LOW-VALUES
              GO TO CARDNUM-NORMALIZE-EXIT
           END-IF

           IF WS-CN-VALUE(1:1) = SPACE
           OR WS-CN-VALUE(1:1) = LOW-VALUES
              MOVE '0'                  TO WS-CN-VALUE(1:1)
              GO TO CARDNUM-NORMALIZE-EXIT
           END-IF

           IF WS-CN-VALUE(17:1) = SPACE
           OR WS-CN-VALUE(17:1) = LOW-VALUES
              MOVE WS-CN-VALUE(1:16)    TO WS-CN-WORK-16
              MOVE '0'                  TO WS-CN-VALUE(1:1)
              MOVE WS-CN-WORK-16        TO WS-CN-VALUE(2:16)
           END-IF
           .

       CARDNUM-NORMALIZE-EXIT.
           EXIT
           .
