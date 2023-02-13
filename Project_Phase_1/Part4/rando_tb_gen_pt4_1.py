# Brian Cheung
# Jinxing Yin

import random
import queue

random_generate = False # Randomly generate a new file
testing_overflow_underflow = False # Generate/test text file for overflow and underflow

# Constants for the system
number_of_test_cases = 1000
number_of_input_bits = 14
number_of_output_bits = 28
valid_in_to_out_delay = 3
numb_of_stages = valid_in_to_out_delay + 2 # This is 1 more then the number of staged to hold the multiplied value

# Converts a number to its two's compliment binary
# integer val: value to be converted to two's compliment
# integer numb_of_bits: number of bits that the number can be converted into
def twos_comp_numb_to_bin(val, numb_of_bits):
    # check if the number has reached saturation
    if val > pow(2, numb_of_bits - 1) - 1:
        trailing_one_string = "1"*(numb_of_bits-1)
        return f"0{trailing_one_string}"
    elif val < pow(2, numb_of_bits - 1) * (-1):
        trailing_zero_string = "0"*(numb_of_bits-1)
        return f"1{trailing_zero_string}"
    
    if val > 0:
        bits = bin(val)
        bits = bits[2:]
        leading_zero_string = "0" * (numb_of_bits - len(bits))
        return f"{leading_zero_string}{bits}"
    elif val < 0:
        absolute_val = abs(val)
        bits = bin(absolute_val)
        bits = bits[2:]
        leading_zero_string = "0" * (numb_of_bits - len(bits))
        bits = f"{leading_zero_string}{bits}"

        bit_list = list(bits)
        for i in range(len(bit_list)):
            if bit_list[i] == "0":
                bit_list[i] = "1"
            else:
                bit_list[i] = "0"

        carry_bit = "1"

        for i in range(len(bit_list)):
            if bit_list[len(bit_list) - i - 1] == "1" and carry_bit == "1":
                bit_list[len(bit_list) - i - 1] = "0"
                carry_bit = "1"
            elif bit_list[len(bit_list) - i - 1] == "0" and carry_bit == "1":
                bit_list[len(bit_list) - i - 1] = "1"
                break

        two_compliment_truncated = "".join(bit_list)[-numb_of_bits:]
        sign_extend_string = two_compliment_truncated[0] * (
            numb_of_bits - len(two_compliment_truncated)
        )
        return f"{sign_extend_string}{two_compliment_truncated}"
    else:
        return "0" * numb_of_bits

# Converts a two's compliment binary number to a integer number
# string bin: a binary string representation of the number
# integer numb_of_bits: the number of bits that the binary number should be to convert to integer
def twos_comp_bin_to_numb(bin, numb_of_bits):
    twos_numb = 0
    twos_numb += (int(bin[0]) * pow(2,numb_of_bits-1)) * (-1)
    for i in range(1, numb_of_bits):
        twos_numb += int(bin[i]) * pow(2,numb_of_bits-i-1)
    return twos_numb


# Queues that delay the output by x cycles
reset_queue = queue.Queue(0) #binary, x=1
valid_out_queue = queue.Queue(0) #binary, x=3+internal_multiplier_registers
mac_stages = [] #list that holds the information on one stage to another
# The [0] element being the a b registers
# The [n-2] element being the pipeline register
# The [n-1] element being the accumulator register

reset_queue.put(0)

for _ in range(valid_in_to_out_delay):
    valid_out_queue.put(0)

for _ in range(numb_of_stages):
    mac_stages.append(0)

# for a random 
if testing_overflow_underflow:
    input_file = open("tb_input_pt4_1_flow.txt", "w")
    output_file = open("tb_output_pt4_1_flow.txt", "w")
    io_test_file = open("tb_io_pt4_1_flow.txt", "w")
else:
    input_file = open("tb_input_pt4_1.txt", "w")
    output_file = open("tb_output_pt4_1.txt", "w")
    io_test_file = open("tb_io_pt4_1.txt", "w")

# Generates a new random input or use an already defined input text file
if random_generate == True:
    if testing_overflow_underflow:
        txt_input = open("input_pt4_1_flow.txt", "w")
    else:
        txt_input = open("input_pt4_1.txt", "w")
else:
    if testing_overflow_underflow:
        txt_input = open("input_pt4_1_flow.txt", "r")
    else:
        txt_input = open("input_pt4_1.txt", "r")
    text_input_list = txt_input.readlines()
    text_random_input_list = []
    for text_input in text_input_list:
        split_truncate_text_input_list = text_input[:len(text_input)-1].split(' ')
        text_random_input_list.append(split_truncate_text_input_list)

print(f"Generating random {number_of_test_cases} inputs...")
print("Values are in the order of: reset, a, b, valid_in, f, valid_out")

# runs number_of_test_cases times to generate tests cases and outputs
for i in range(number_of_test_cases):
    # randomly generates inputs to write to simulate and write to file
    # or reads inputs that has been previously generated
    if random_generate == True:
        if testing_overflow_underflow:
            random_reset = 100
        else:
            random_reset = random.randint(0, 100)
            
        if random_reset > 10:
            reset = 0
        else:
            reset = 1
        a = random.randint(
            (-1) * pow(2, number_of_input_bits - 1), pow(2, number_of_input_bits - 1) - 1
        )
        b = random.randint(
            (-1) * pow(2, number_of_input_bits - 1), pow(2, number_of_input_bits - 1) - 1
        )
        valid_in = random.randint(0, 1)
    else:
        reset = int(text_random_input_list[i][0])
        a = int(text_random_input_list[i][1])
        b = int(text_random_input_list[i][2])
        valid_in = int(text_random_input_list[i][3])
    
    # Get binary version of a and b for the input text file
    a_bin = twos_comp_numb_to_bin(a, number_of_input_bits)
    b_bin = twos_comp_numb_to_bin(b, number_of_input_bits)
    
    # puts in the valid_in and reset to be delayed for x cycles
    # gets the valid_out and reset that has been delayed for x cycles
    valid_out_queue.put(valid_in)
    reset_queue.put(reset)
    valid_out = valid_out_queue.get()
    reset_signal = reset_queue.get()
        
    # a b register (multiplication performed already for simplicity)
    if valid_in == 1 and reset == 0:
        multiplier = a * b
        mac_stages[0] = multiplier
    
    # accumulator register, accumulate if has not been reset, do nothing if it hasn't been reset
    if reset_signal == 0:
        accumulator_sum = mac_stages[numb_of_stages-1] + mac_stages[numb_of_stages-2]
        twos_bin_and_saturate = twos_comp_numb_to_bin(accumulator_sum, number_of_output_bits)
        accumulator_sum_out = twos_comp_bin_to_numb(twos_bin_and_saturate, number_of_output_bits)
        mac_stages[numb_of_stages-1] = accumulator_sum_out
    
    # reset all registers if reset is set    
    if reset_signal == 1:
        for i in range(1, numb_of_stages):
            mac_stages[i] = 0
        for _ in range(valid_in_to_out_delay-1):
            valid_out_queue.get() #replaced valid_in_to_out_delay with valid_out = 0
        n_cycle_delayed = valid_out_queue.get()
        for _ in range(valid_in_to_out_delay-1):
            valid_out_queue.put(0) #replaced valid_in_to_out_delay with valid_out = 0
        valid_out_queue.put(n_cycle_delayed)
        valid_out = 0
    
    #trigers the "registers" to output its input into its output (next stage)
    for i in range(numb_of_stages-2, 0, -1):
        mac_stages[i] = mac_stages[i-1]
    mac_stages[0] = 0 #resets multiplier holder
    
    # output the current output of the accumulator register
    accumulator_out = mac_stages[numb_of_stages-1]

    # write to input and output files
    input_file.write(f"{reset}\n{a_bin}\n{b_bin}\n{valid_in}\n")
    output_file.write(f"{valid_out}\t{accumulator_out}\n")
    io_test_file.write(f"reset: {reset}\t|a: {a}\t|b: {b}\t|valid_in: {valid_in}\t|accumulator_out: {accumulator_out}\t|valid_out: {valid_out}\n")
    if random_generate == True:
        txt_input.write(f"{reset} {a} {b} {valid_in}\n")
