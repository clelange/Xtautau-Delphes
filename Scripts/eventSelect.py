import ROOT
import sys
ROOT.gSystem.Load("libDelphes")
ROOT.gInterpreter.Declare('#include "classes/DelphesClasses.h"')
ROOT.gInterpreter.Declare('#include "external/ExRootAnalysis/ExRootTreeReader.h"')

inputFile = sys.argv[1]
outputFile = sys.argv[2]

chain = ROOT.TChain("Delphes")
chain.Add(inputFile)
treeReader = ROOT.ExRootTreeReader(chain)
numberOfEntries = treeReader.GetEntries()
genParticle = treeReader.UseBranch("Particle")

print "found %d events in inputfile" % numberOfEntries

uselessPIDs = [12,14,16,22,15]
selectedEvents = []

print "processing..."

for entry in xrange(0, numberOfEntries):
	treeReader.ReadEntry(entry)
	nParticles = genParticle.GetEntries()
	if(nParticles <=0):
		continue
	taus=[]
	#print entry
	for index in xrange(nParticles):
		particle = genParticle.At(index)
		if  abs(particle.PID) == 15:
			taus.append(index)
			#print particle.PID, genParticle.At(particle.M1).PID

	decayParticles = []
	visDecayParticles= []
	for tau in taus:
		for particle in genParticle:
			if tau in (particle.M1, particle.M2):
				decayParticles.append(particle)
				if abs(particle.PID) not in uselessPIDs:
					visDecayParticles.append(particle)

	skimEvent = False
	for particle in visDecayParticles:
		pt = particle.PT
		eta = particle.Eta

		if pt < 15 or eta > 2.5:
			skimEvent = True
		#print particle.PID,

	if not skimEvent:
		selectedEvents.append(entry)
	#print "\r ->processing event ", entry,

newFile = ROOT.TFile(outputFile,'recreate')

eventList = ROOT.TEventList()
for event in selectedEvents:
	eventList.Enter(event)
chain.SetBranchStatus("*",1)
chain.SetEventList(eventList)
newTree = chain.CopyTree("1")

newTree.Write()
newFile.Close()
print "%d events written to file %s" % (len(selectedEvents), outputFile)

