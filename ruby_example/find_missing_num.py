my_list = [1, 20, 3, 4, 70]

missing = []

i = 0
while i < len(my_list):
	if i != len(my_list) - 1:
		j = my_list[i] + 1
		while j < my_list[i+1]:
			missing.append(j)
			j += 1
	i += 1

print(missing)