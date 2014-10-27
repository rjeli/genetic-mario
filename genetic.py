import socket
import struct
import sys
import random

NET_A =     0x01
NET_B =     0x02
NET_LEFT =  0x04
NET_RIGHT = 0x08
NET_UP =    0x10
NET_DOWN =  0x20

CHROMOSOME_LENGTH = 12000

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

server_address = ('localhost', 5000)
print >>sys.stderr, 'starting server at %s port %s' % server_address
sock.bind(server_address)

sock.listen(1)

class Chromosome:
    def __init__(self):
        self.genes = []

population = []

n = int(raw_input("how many chromosomes in the pool? "))

print("stirring the primordial soup...")

for i in xrange(n):
    population.append(Chromosome())
    for j in xrange(CHROMOSOME_LENGTH):
        population[i].genes.append(random.randint(0, 255))

currentChromosome = 0
currentGene = 0

fitness = {}

def weightedSelect(choices):
    total = sum(choices.values())
    pick = random.uniform(0, total)
    current = 0
    for k, v in choices.iteritems():
        current += v
        if current > pick:
            return k

def sex(parentA, parentB):
    child = Chromosome()
    f = random.randint(0, 1)
    for i in xrange(CHROMOSOME_LENGTH):
        if random.uniform(0, 1) < 0.008:
            f = not f
        if random.uniform(0, 1) < 0.01:
            child.genes.append(random.randint(0, 255))
        else:
            if f:
                child.genes.append(parentA.genes[i])
            else:
                child.genes.append(parentB.genes[i])
    return child

print("genes created, ready to play")

generation = 0

while True:
    # wait for connection
    connection, client_address = sock.accept()

    try:
        data = connection.recv(16)

        if currentGene >= CHROMOSOME_LENGTH:
            print("the end of the gene has been reached... idk if this can happen")
            currentGene = 0
            currentChromosome += 1

        if currentChromosome >= len(population):
            average = str(float(sum(fitness.values())/len(fitness.values())))
            with open("log.txt", "a") as myfile:
                myfile.write(average + " " + str(max(fitness.values())) + "\n")
            print("generation " + str(generation) + " complete. average fitness = " + average + ", peak = " + str(max(fitness.values())))
            generation += 1
            print("calculating new generation...")
            newPopulation = []
            for i in xrange(n):
                parentA = weightedSelect(fitness)
                parentB = weightedSelect(fitness)
                while parentB == parentA:
                    parentB = weightedSelect(fitness)
                newPopulation.append(sex(population[parentA], population[parentB]))
            population = newPopulation
            currentChromosome = 0

        if data == "req":
            connection.sendall(struct.pack('B', population[currentChromosome].genes[currentGene]))
            currentGene += 1
        else:
            print("chromosome " + str(currentChromosome) + " died, fitness = " + data)
            fitness[currentChromosome] = int(data)
            currentChromosome += 1
            currentGene = 0

    finally:
        connection.close()
