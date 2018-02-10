//Simple pt/eta event selection macro for delphes output files

#ifdef __CLING__
R__LOAD_LIBRARY(libDelphes)
#include "classes/DelphesClasses.h"
#include "external/ExRootAnalysis/ExRootTreeReader.h"
#include <vector>
#include <iostream>
#include "TEventList.h"
#include "TClonesArray.h"
#include "TSystem.h"
#endif
using namespace std;

int eventSelect(char *arg1, char *arg2){

	//temporary hardcoded inputfile
	//const char *inputFile = "root://eoscms.cern.ch///eos/cms/store/cmst3/group/exovv/clange/Xtautau/100/1/Xtautau_delphes_events.root";
	const char *inputFile = arg1;

	//const char *outputFile = "skimmed.root";
	const char *outputFile = arg2;


	const vector<Int_t> badPIDs = {12,14,15,16,22};
	bool skimEvent = false;

	//cout << "input path:" << inputFile << endl;

	gSystem->Load("libDelphes");
	TChain chain("Delphes");
	chain.Add(inputFile);
	ExRootTreeReader *treeReader = new ExRootTreeReader(&chain);
	Long64_t numberOfEntries = treeReader->GetEntries();
	TClonesArray *branchGenParticle = treeReader->UseBranch("Particle");

	GenParticle *particle;
	vector<Int_t> selectedEvents;

	if(branchGenParticle == NULL) return -1;

	cout << "verified input. starting analysis...." << endl;
	for(Int_t entry = 0; entry < numberOfEntries; ++entry)
	{
		//early break for testing
		//if(entry > 200) break;

		//cout << "event " << entry << " of " << numberOfEntries << endl;

		treeReader->ReadEntry(entry);
		Long64_t nParticles = branchGenParticle->GetEntriesFast();

		//Verify event contains particles
		if(nParticles <= 0) continue;

		Int_t numberOfTaus = 0;
		vector<Int_t> tauIndices;

		//Find taus in dataset
		for(Int_t particleIndex = 0; particleIndex < nParticles; ++particleIndex)
		{
			particle = (GenParticle*) branchGenParticle->At(particleIndex);

			if(particle->M1 == -1) continue;

			GenParticle *M1 = (GenParticle*) branchGenParticle->At(particle->M1);

			if(abs(particle->PID) == 15 && abs(M1->PID) == 25)
			{
				//cout << particle->PID <<","<< M1->PID << endl;
				tauIndices.push_back(particleIndex);
				numberOfTaus++;
			}
		}

		//cout << "numberOfTaus " << numberOfTaus << ", indices: tau 0 "<< tauIndices[0] << " tau 1 " << tauIndices[1] << endl;

		if(numberOfTaus > 2)
		{
			cout << "number of taus " << numberOfTaus << endl;
			continue;
		}

		//Collect decay particle indices.
		vector<Int_t> decayIndices;
		vector<Int_t> visDecayIndices;
		for(Int_t particleIndex = 0; particleIndex < nParticles; ++particleIndex)
		{
			particle = (GenParticle*) branchGenParticle->At(particleIndex);

			if(find(tauIndices.begin(), tauIndices.end(), particle->M1) != tauIndices.end()
				|| find(tauIndices.begin(), tauIndices.end(), particle->M2) != tauIndices.end())
			{
				//cout << particle->PID << " ";
				decayIndices.push_back(particleIndex);

				if(!(find(badPIDs.begin(), badPIDs.end(), abs(particle->PID)) != badPIDs.end()) )
				{
					//cout << particle->PID << " ";
					visDecayIndices.push_back(particleIndex);
				}
			}
		}

		//cout << endl;
		Int_t numberOfVisDecays = visDecayIndices.size();
		//cout << "size visdecays: " <<  numberOfVisDecays << endl;

		if(numberOfVisDecays <= 0) continue;

		skimEvent = false;
		for(Int_t i = 0; i<numberOfVisDecays; ++i)
		{
			GenParticle *vis = (GenParticle*) branchGenParticle->At(visDecayIndices[i]);
			Double_t pt  = vis->PT;
			Double_t eta = vis->Eta;
			//cout << "pt "<< pt << " eta " << eta << endl;
			if( pt < 15 || abs(eta) > 2.5)
			{
				skimEvent = true;
			}
		}

		if(!skimEvent)
		{
			//cout << "selected event" << endl;
			selectedEvents.push_back(entry);
		}else{
			//cout << "skimmed event" << endl;
		}
	}

	cout << "nuber of selected events " << selectedEvents.size() << endl;

	TFile *newFile = new TFile(outputFile,"recreate");

	TEventList *eventList = new TEventList();
	for(Int_t i = 0; i<selectedEvents.size(); ++i)
	{
		eventList->Enter(selectedEvents[i]);
	}
	chain.SetBranchStatus("*",1);
	chain.SetEventList(eventList);

	TTree *newTree = chain.CopyTree("1");

	cout << "completed" << endl;

	newTree->Write();
	newFile->Close();

	return EXIT_SUCCESS;

}
