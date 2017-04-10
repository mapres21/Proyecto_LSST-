import numpy as np
import matplotlib.pyplot as plt

# Matriz que contiene los datos
Matriz = np.genfromtxt("Star_1.csv", delimiter=",")

# Vectores con cada una de las bandas y los errores
U_band = Matriz[:, 0]
G_band = Matriz[:, 1]
R_band = Matriz[:, 2]
I_band = Matriz[:, 3]
Z_band = Matriz[:, 4]
EU_band = Matriz[:, 5]
EG_band = Matriz[:, 6]
ER_band = Matriz[:, 7]
EI_band = Matriz[:, 8]
EZ_band = Matriz[:, 9]

U_mean = np.mean(U_band)
G_mean = np.mean(G_band)
R_mean = np.mean(R_band)
I_mean = np.mean(I_band)
Z_mean = np.mean(Z_band)

U_mean1 = 18.52
G_mean1 = 17.26
R_mean1 = 17.24
I_mean1 = 17.34
Z_mean1 = 17.39

x = np.arange(0, 43, 1)

# Grafica
plt.figure()
plt.plot(x, U_band, 'bo', label='Magnitude')
plt.hlines(y=U_mean, xmin=0, xmax=44, color='r', label='Found value')
plt.hlines(y=U_mean1, xmin=0, xmax=44, color='g', label='Mean value')
# plt.errorbar(x, U_band, yerr=EU_band, fmt='o', ecolor='b')
plt.ylabel("Magnitude")
plt.xlabel("Observation's night")
plt.title("U Band")
plt.grid()
plt.legend(loc='upper right')
plt.savefig("U.png")
plt.show(True)

plt.figure()
plt.plot(x, G_band, 'bo', label='Magnitude')
plt.hlines(y=G_mean, xmin=0, xmax=44, color='r', label='Found value')
plt.hlines(y=G_mean1, xmin=0, xmax=44, color='g', label='Mean value')
# plt.errorbar(x, U_band, yerr=EU_band, fmt='o', ecolor='b')
plt.ylabel("Magnitude")
plt.xlabel("Observation's night")
plt.title("G Band")
plt.grid()
plt.legend(loc='upper right')
plt.savefig("G.png")
plt.show(True)

plt.figure()
plt.plot(x, R_band, 'bo', label='Magnitude')
plt.hlines(y=R_mean, xmin=0, xmax=44, color='r', label='Found value')
plt.hlines(y=R_mean1, xmin=0, xmax=44, color='g', label='Mean value')
# plt.errorbar(x, U_band, yerr=EU_band, fmt='o', ecolor='b')
plt.ylabel("Magnitude")
plt.xlabel("Observation's night")
plt.title("R Band")
plt.grid()
plt.legend(loc='upper right')
plt.savefig("R.png")
plt.show(True)


plt.figure()
plt.plot(x, I_band, 'bo', label='Magnitude')
plt.hlines(y=I_mean, xmin=0, xmax=44, color='r', label='Found value')
plt.hlines(y=I_mean1, xmin=0, xmax=44, color='g', label='Mean value')
# plt.errorbar(x, U_band, yerr=EU_band, fmt='o', ecolor='b')
plt.ylabel("Magnitude")
plt.xlabel("Observation's night")
plt.title("I Band")
plt.grid()
plt.legend(loc='upper right')
plt.savefig("I.png")
plt.show(True)

plt.figure()
plt.plot(x, Z_band, 'bo', label='Magnitude')
plt.hlines(y=Z_mean, xmin=0, xmax=44, color='r', label='Found value')
plt.hlines(y=Z_mean1, xmin=0, xmax=44, color='g', label='Mean value')
# plt.errorbar(x, U_band, yerr=EU_band, fmt='o', ecolor='b')
plt.ylabel("Magnitude")
plt.xlabel("Observation's night")
plt.title("Z Band")
plt.grid()
plt.legend(loc='upper right')
plt.savefig("Z.png")
plt.show(True)

