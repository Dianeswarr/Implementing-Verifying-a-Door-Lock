module keypad(
    input [3:0] key,
    input pressed,
    input clk,
    output reg [15:0] last4
    );
reg  [15:0] x;
initial begin
 x=0;
last4=0;
end
 


  always@ (posedge clk)
       begin
       
         if ( pressed) begin
            x= (x % 1000)*10 + key;
           
            end
         else begin
           x=x;  
         end
         last4 =x;
        
        end
 
   
endmodule

module ReqKeyPad(input [3:0] key,
                 input pressed,
                 input clk);

   wire [15:0] last4;
   reg [3:0] previous_key;
reg [15:0]  pre_a;


   keypad kp(key, pressed, clk,last4);
   

     always @(posedge clk) begin
     
            previous_key =key;
             pre_a = last4;
           end
     
     
     
 

     

 
   assume property (key >= 0 && key<=10); // the input key is a number in the interval [0, 10)

   assert property (!pressed |=>  (pre_a==last4));  //  If no key is pressed, the output stays the same in the next cycle

   assert property (pressed |=>  (last4%10 == previous_key)); // If a key is pressed, the output last4 is updated within 1 cycle, and the remainder of the new output modulo 10 will be the code of the pressed key

   assert property (last4>=0 && last4<=10000);  //The output last4 is an integer in the interval [0, 10000)
 

endmodule

//////////////////////////////////////////////////////////////////////

module control(output reg code_matches,
               input pressed,
               input  [15:0] last4,
               input set_code,
               input clk);


reg previous_pressed;
reg [15:0] code;
reg set_cd;
initial begin
code_matches = 0;
previous_pressed = 0;
set_cd = 0;
end
 always @ (posedge clk) begin
 
if (set_code == 1)
begin
 code <= last4;
 set_cd <= 1;
 end
 
if (pressed && set_cd) begin
            if (last4 == code)
 code_matches <= 1;
            else
                code_matches <= 0;
            end

else if(!pressed)
code_matches <= 0;

 previous_pressed <= pressed;  
 end
 endmodule

module ReqControl(input pressed,
                  input [15:0] last4,
                  input set_code,
                  input clk);

   wire code_matches;
   control ctrl(code_matches, pressed, last4, set_code, clk);

reg [15:0] code;
reg previous_pressed;
reg set_cd;

initial begin
previous_pressed = 0;
code = 0;
set_cd = 0;

end

always @ (posedge clk) begin
if (set_code)
set_cd <= 1;


previous_pressed <= pressed;
end



assume property (last4 >= 0 && last4 <10000);//the input last4 is a number in the interval [0, 10000)

assert property (!set_cd |-> !code_matches); // If no code has been set using the set_code input, the door will not be unlocked

assert property (code_matches|-> previous_pressed  ); //The controller will unlock the door only if a key press occurred in the previous cycle

endmodule

//////////////////////////////////////////////////////////////////////

module Lock(output unlocked,
            input [3:0] key,
            input pressed,
            input set_code,
            input clk);

   wire [15:0] last4;
   wire code_matches;

   // we delay the signals pressed and set_code going to the controller
   // by one cycle, to compensate for the delay of last4 introduced
   // by the keypad

   reg pre_pressed = 0, pre_set_code = 0;
   always @(posedge clk) begin
     pre_pressed = pressed;
     pre_set_code = set_code;
   end

    keypad k1(key, pressed, clk,last4);
   control ctrl(code_matches, pre_pressed, last4, pre_set_code, clk);

   reg [3:0] i = 15;
   always @(posedge clk) begin
     if (code_matches)
       i = 0;
     else if (i < 15)
       i = i + 1;
   end

   assign unlocked = code_matches || i < 9;

endmodule

module ReqLock(input [3:0] key,
               input pressed,
               input set_code,
               input clk);

   wire unlocked;
   reg [4:0] counter = 0;
   Lock lock(unlocked, key, pressed, set_code, clk);
   
   always @(posedge clk) begin
     if (pressed)
       counter = 0;
     else if (unlocked)
       counter = counter + 1;
   end

   // Add requirements R1, R2, and assumption E1 here

   assume property (key >= 0 && key < 10); //the input key is a number in the interval [0, 10)

   assert property(!pressed |=> !pressed && !unlocked|=> !unlocked);//  If no key is pressed and the door is locked, then the door stays locked

   assert property(counter <= 11); // If the door is unlocked and no key is pressed, the door is locked within 10 cycles

   // Bonus requirement:
   // After setting the code to 1234,
   // entering 1234 again will unlock the door
   assert property (key == 1 && pressed |=>
                    key == 2 && pressed |=>
                    key == 3 && pressed |=>
                    key == 4 && pressed |=>
                    !pressed && set_code |=>
                    key == 1 && pressed && !set_code |=>
                    key == 2 && pressed && !set_code |=>
                    key == 3 && pressed && !set_code |=>
                    key == 4 && pressed && !set_code |=>
                    ##1 unlocked);

endmodule