# Replace with the actual path to your file
file_path = "done/dhry.hex"

#num 32 bit words
LEN=1024*16
ARR=[]
i=0
while i<LEN*4 :
	ARR.append("00")
	i=i+1

ADDR=0

try:
	with open(file_path, 'r') as file:
		for line in file:
			# Process each line here
			if line[0]=='@' :
				line = line[1:]
				ADDR = int(int(line, 16))
				#print("SET ADDR",ADDR)
				continue
			#print(line.strip())  # .strip() removes leading/trailing whitespace, including newline characters
			words = line.split()
			for W in words :
				ARR[ADDR]=W
				ADDR=ADDR+1
except FileNotFoundError:
	print(f"Error: The file '{file_path}' was not found.")
except Exception as e:
	print(f"An error occurred: {e}")

i=0
while i<LEN :
	w32 = ARR[i*4+3]+ARR[i*4+2]+ARR[i*4+1]+ARR[i*4+0]
	print(w32)
	i=i+1
