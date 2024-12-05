with open("input.txt") as file:
    data = file.read().split("mul(")

total1, total2 = 0, 0
on = True

for seq in data:
    seqparse = seq.split(",", 1)
    firstval = seqparse[0]
    if firstval.isdigit():
        secondval = seqparse[1].split(")")[0]
        if secondval.isdigit():
            total1 += int(firstval)*int(secondval)
            if on: total2 += int(firstval)*int(secondval)
    if seq.find("don't()") > seq.find("do()"): on = False
    if seq.find("do()") > seq.find("don't()"): on = True

print(total1, total2)
