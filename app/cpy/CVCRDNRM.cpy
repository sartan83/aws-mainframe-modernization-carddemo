      ******************************************************************
      * Card number normalization work area (16 to 17 digit migration)
      * A legacy 16 digit card number is represented as a left zero
      * padded 17 digit value ('0' followed by the 16 digits).
      ******************************************************************
       01  WS-CARDNUM-NORM.
           05  WS-CN-VALUE                       PIC X(17).
           05  WS-CN-WORK-16                     PIC X(16).
