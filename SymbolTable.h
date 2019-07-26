#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include<bits/stdc++.h>
using namespace std;
typedef pair<int,int>PII;
/*
ostream &operator<<(ostream &out, const PII &p)
{
    return out << "(" << p.first << "," << p.second << ")";
}
*/

extern ofstream logout;

class SymbolInfo {
    typedef SymbolInfo* SymbolInfoPtr;

    string name, type;
    SymbolInfoPtr nextSymbol;
	
	string variableType;
	bool array, function;

public:

    SymbolInfo(string name, string type) : name(name), type(type), nextSymbol(nullptr) {
		variableType = "";
		array = false;
		function = false;
	}

	void setArray() {
		array = true;
	}

	bool isArray() {
		return array;
	}

	void setFunction() {
		function = true;
	}

	bool isFunction() {
		return function;
	}

	bool isVoid() {
		return variableType=="void";
	}
	bool isFloat() {
		return variableType=="float";
	}
	bool isInt() {
		return variableType=="int";
	}

	void setVariableType(string type) {
        this->variableType = type;
    }

	string getVariableType() {
        return variableType;
    }

    void setName(string name) {
        this->name = name;
    }
    void setType(string type) {
        this->type = type;
    }
    void setNextSymbol(SymbolInfoPtr nextSymbol) {
        this->nextSymbol = nextSymbol;
    }
    string getName() const {
        return name;
    }
    string getType() const {
        return type;
    }
		
	void copyValues(SymbolInfoPtr sip) {
		variableType = sip->variableType;
		array = sip->array;
		function = sip->function;
	}
	
    SymbolInfoPtr getNextSymbol() {
        return nextSymbol;
    }
    bool hasNext() {
        return nextSymbol!=nullptr;
    }
	void print(ostream &out) {
		out << "< " << getName() << " : " << getType();
		if (!variableType.empty()) out << " : " << variableType;
		if (isFunction()) out << " : isFunction";
		if (isArray()) out << " : isArray";
		out << " >";
	}
};

typedef SymbolInfo* SymbolInfoPtr;

class ScopeTable {
    typedef ScopeTable* ScopeTablePtr;
    const int BASE = 317;

    static int objectCounter;

    int n, id;
    SymbolInfoPtr* table;

    ScopeTablePtr parentScope;

    int djb2(string key) {
        unsigned int hash = 5381;
        for (char c : key)
            hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
        return hash;
    }

    int getHashValue(string key) {
        return djb2(key)%n;
    }

public:
    ScopeTable(int n) {
        id = ++objectCounter;
		//cout << "id " << id << " created" << endl;
		logout << "id " << id << " created" << endl;
        parentScope = nullptr;
        this->n = n;
        table = new SymbolInfoPtr[n];
        for (int i = 0; i < n; i++) table[i] = nullptr;
    }

    ~ScopeTable() {
        for (int i = 0; i < n; i++) {
            while (table[i]!=nullptr) {
                SymbolInfoPtr tmp = table[i];
                table[i] = table[i]->getNextSymbol();
                delete tmp;
            }
        }
        delete[] table;
    }

    SymbolInfoPtr lookUp(string name) {
        int idx = getHashValue(name);
        SymbolInfoPtr sip = table[idx];
        while (sip != nullptr) {
            if (sip->getName()==name) return sip;
            sip = sip->getNextSymbol();
        }
        return nullptr;
    }

    PII indexLookUp(string name) {
        PII idx;
        idx.first = getHashValue(name);
        SymbolInfoPtr sip = table[idx.first];
        idx.second = 0;
        while (sip != nullptr) {
            if (sip->getName()==name) return idx;
            sip = sip->getNextSymbol();
            idx.second++;
        }
        idx.second = -1;
        return idx;
    }

    bool insert(string name, string type) {
        SymbolInfoPtr old = lookUp(name);
        if (old!=nullptr) {
            return false;
        }
        int idx = getHashValue(name);
        SymbolInfoPtr sip = new SymbolInfo(name, type);
        sip->setNextSymbol(table[idx]);
        table[idx] = sip;

        //cout << "Inserted in ScopeTable# " << id << " at position " << indexLookUp(name) << endl;

        return true;
    }

    bool remove(string name) {
        SymbolInfoPtr sip = lookUp(name);
        if (sip==nullptr) {
            return false;
        }
        //cout << "Deleted entry at " << indexLookUp(name) <<
        //        " from current ScopeTable" << endl;

        int idx = getHashValue(name);
        if (sip==table[idx]) {
            table[idx] = table[idx]->getNextSymbol();
        } else {
            SymbolInfoPtr itr = table[idx];
            while (itr->getNextSymbol()!=sip) itr = itr->getNextSymbol();
            itr->setNextSymbol(sip->getNextSymbol());
        }
        delete sip;
        return true;
    }

    int getBucketSize() const {
        return n;
    }

    void setParentScope(ScopeTablePtr stp) {
        parentScope = stp;
    }

    ScopeTablePtr getParentScope() const {
        return parentScope;
    }

    int getScopeId() const {
        return id;
    }

    SymbolInfoPtr getList(int idx) const {
        assert(0 <= idx && idx < n);
        return table[idx];
    }

	void print(ostream &out) {
		out << "ScopeTable # " << getScopeId() << endl;
		for (int i = 0; i < getBucketSize(); i++) {
		    out << i << " -->";
		    SymbolInfoPtr sip = getList(i);
		    while (sip != nullptr) {
		        out << " "; sip->print(out);
		        sip = sip->getNextSymbol();
		    }
		    out << endl;
		}
	}
};


typedef ScopeTable* ScopeTablePtr;

class SymbolTable {
    int bucketSize;
    ScopeTablePtr stack;

public:
    SymbolTable(int bucketSize) : bucketSize(bucketSize) {
        //stack = new ScopeTable(bucketSize);
    }

    ~SymbolTable() {
        while (stack != nullptr) {
            ScopeTablePtr stp = stack;
            stack = stack->getParentScope();
            delete stp;
        }
    }

    void enterScope() {
        ScopeTablePtr stp = new ScopeTable(bucketSize);
        stp->setParentScope(stack);
        stack = stp;

        //cout << "New ScopeTable with id " << stack->getScopeId() << " created" << endl;
    }

    void exitScope() {
        if (stack->getParentScope()==nullptr) {
            //cout << "Error: Can't escape main scope!!" << endl;
            return;
        }
        //cout << "ScopeTable with id " << stack->getScopeId() <<" removed" << endl;
        ScopeTablePtr tmp = stack;
        stack = stack->getParentScope();
        delete tmp;
    }

    bool insert(string name, string type) {
        return stack->insert(name, type);
    }
    bool remove(string name) {
        return stack->remove(name);
    }
    SymbolInfoPtr lookUp(string name) {
        ScopeTablePtr stp = stack;
        while (stp != nullptr) {
            SymbolInfoPtr sip = stp->lookUp(name);
            if (sip!=nullptr) {
                return sip;
            }
            stp = stp->getParentScope();
        }
        return nullptr;
    }

    void printCurrentScopeTable(ostream &out) {
		stack->print(out);
    }
    void printAllScopeTable(ostream &out) {
        ScopeTablePtr stp = stack;
        while (stp != nullptr) {
			stp->print(out);
            stp = stp->getParentScope();
        }
    }
};

#endif
