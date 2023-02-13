# Brian Cheung
# Jinxing Yin

import random
import queue

random_generate = False # Randomly generate a new file
testing_overflow_underflow = False # Generate/test text file for overflow and underflow

# constants
number_of_test_cases = 1000
number_of_input_bits = 14
number_of_output_bits = 28

# Converts a number to its two's compliment binary (truncates when values are larger then number of bits)
# integer val: value to be converted to two's compliment
# integer numb_of_bits: number of bits that the number can be converted into
def twos_comp_numb_to_bin(val, numb_of_bits):
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

# input and outputs files
if testing_overflow_underflow:
    input_file = open("tb_input_pt2_flow.txt", "w")
    output_file = open("tb_output_pt2_flow.txt", "w")
    io_test_file = open("tb_io_pt2_flow.txt", "w")
else:
    input_file = open("tb_input_pt2.txt", "w")
    output_file = open("tb_output_pt2.txt", "w")
    io_test_file = open("tb_io_pt2.txt", "w")
    
# Generates a new random input or use an already defined input text file
if random_generate == True:
    if testing_overflow_underflow:
        txt_input = open("input_pt2_flow.txt", "w")
    else:
        txt_input = open("input_pt2.txt", "w")
else:
    if testing_overflow_underflow:
        txt_input = open("input_pt2_flow.txt", "r")
    else:
        txt_input = open("input_pt2.txt", "r")
    text_input_list = txt_input.readlines()
    text_random_input_list = []
    for text_input in text_input_list:
        split_truncate_text_input_list = text_input[:len(text_input)-1].split(' ')
        text_random_input_list.append(split_truncate_text_input_list)

# queues to simulate the delay in the circuit from registers
reset_queue = queue.Queue(0) #binary
multiplier_queue = queue.Queue(0) #integer
enable_accumulator_queue = queue.Queue(0) #binary
accumulator_queue = queue.Queue(0) #integer
valid_out_queue = queue.Queue(0) #binary
temp_valid_out_queue = queue.Queue(0) #binary

reset_queue.put(0)
multiplier_queue.put(0)
enable_accumulator_queue.put(0)
accumulator_queue.put(0)
valid_out_queue.put(0)
valid_out_queue.put(0)

print(f"Generating random {number_of_test_cases} inputs...")
print("Values are in the order of: reset, a, b, valid_in, f, valid_out")

for i in range(number_of_test_cases):
    # randomly generates inputs to write to simulate and write to file
    # or reads inputs that has been previously generated
    if random_generate == True:
        #generates random inputs, reset can be hardcoded to 0 to forcibly simulate overflow and underflow behaviour
        if testing_overflow_underflow:
            reset = 0
        else:
            reset = random.randint(0, 1)
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
    
    valid_out_queue.put(valid_in)
    enable_accumulator_queue.put(valid_in)
   
    # converts integer to binary
    a_bin = twos_comp_numb_to_bin(a, number_of_input_bits)
    b_bin = twos_comp_numb_to_bin(b, number_of_input_bits)
    
    # reset
    if reset == 1:
        reset_queue.put(1)
    else:
        reset_queue.put(0)
        
    # get the delayed control signals and outputs
    reset_signal = reset_queue.get()
    multiplier_out = multiplier_queue.get()
    enable_accumulator = enable_accumulator_queue.get()
    accumulator_out = accumulator_queue.get()
    valid_out = valid_out_queue.get()
    
    #reset all current output values when reset
    if reset_signal == 1:
        multiplier_out = 0
        enable_accumulator = 0
        accumulator_out = 0
        valid_out = 0
        valid_out_queue.get() #one cycle delayed removed, replaced with valid_out = 0
        two_cycle_delayed = valid_out_queue.get()
        valid_out_queue.put(0)
        valid_out_queue.put(two_cycle_delayed)
    
    # a b register (already multiplied)
    if valid_in == 1:
        multiplier = a * b
        multiplier_queue.put(multiplier)
    else:
        multiplier_queue.put(0)
    
    # accumulator register
    if enable_accumulator == 1 and reset_signal == 0:
        accumulator_sum = accumulator_out + multiplier_out
        twos_bin_and_truncate = twos_comp_numb_to_bin(accumulator_sum, number_of_output_bits)
        accumulator_sum_out = twos_comp_bin_to_numb(twos_bin_and_truncate, number_of_output_bits)
        accumulator_queue.put(accumulator_sum_out)
    elif reset_signal == 1:
        accumulator_queue.put(0)
    else:
        accumulator_queue.put(accumulator_out)

    # write to input outbut files
    input_file.write(f"{reset}\n{a_bin}\n{b_bin}\n{valid_in}\n")
    output_file.write(f"{valid_out}\t{accumulator_out}\n")
    io_test_file.write(f"reset: {reset}\t|a: {a}\t|b: {b}\t|valid_in: {valid_in}\t|accumulator_out: {accumulator_out}\t|valid_out: {valid_out}\n")
    if random_generate == True:
        txt_input.write(f"{reset} {a} {b} {valid_in}\n")
