#!/bin/bash
bestFit(){}

firstNextFist(){
    startPunkt=1
    prozessgroese=$1
    if [ "$dynamicKonzept" == "next" ];then
        startPunkt=$2
    fi
    freieStelleCounter=$1;
    start=0
    ende=0
    for ((i=$startPunkt; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
        if [[ -z "${matrix[$i,$j]}"  && $freieStelleCounter -gt 0 ]]; then
           ((freieStelleCounter -= 1))
          ende=$i
        fi
        if [[ -n "${matrix[$i,$j]}"  ]]; then
        freieStelleCounter=$1
        fi
          if [[ $freieStelleCounter -eq 0  ]]; then 
            start=$((ende - prozessgroese + 1))
            echo "$start $ende"
            break 3
        fi
        if [[ $freieStelleCounter -gt 0 && i -ge $matrixLaenge  ]]; then
            startPunkt=1
            matrixLaenge=$2
            freieStelleCounter=$1
            i=$startPunkt
        fi
        done
    done
}

addProzessDynamic() {
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    prozessName=$(echo "$1" | cut -d',' -f1)
    if [[ "$dynamicKonzept" == "first" || "$dynamicKonzept" == "next" ]]; then
    startEnde=$(firstNextFist $pgroesse $lastindex)
    fi
    if [[ "$dynamicKonzept" == "best" ]]; then
    startEnde=$(bestFit $pgroesse)
    fi
    read -r start ende <<< "$startEnde"
    # echo "Start: $start"
    # echo "Ende: $ende"
    lastindex=$((ende + 1))
    for ((i=start; i<=ende; i++)); do
        for ((j=2; j<=2; j++)); do
                matrix[$i,$j]=$prozessName
        done
    done
}

addProzessStatic() {
    platzgefunden=0
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    for ((i=1; i<=anzahlPartitonen; i++)); do
        for ((j=2; j<=2; j++)); do
            if [[ -z "${matrix[$i,$j]}" && $platzgefunden -eq 0 && $pgroesse -le $partitionsgroeseInpotenz ]]; then
                matrix[$i,$j]=$1
                platzgefunden=1
            fi
        done
    done
}

removeProzessStatic() {
    for ((i=1; i<=anzahlPartitonen; i++)); do
        for ((j=2; j<=2; j++)); do
            prozess="${matrix[$i,$j]}"
            matrixProzess=$(echo "$prozess" | cut -d',' -f1 )
            if [[ "$matrixProzess" == "$1" ]]; then
                matrix[$i,$j]=""
            fi
        done
    done
}

readFile() {
    while IFS= read -r line || [[ -n $line ]]; do
        line=$(echo "$line" | tr -d '\r')
        anweisung=$(echo "$line" | cut -d' ' -f1)
        prozess=$(echo "$line" | cut -d' ' -f2)
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "static" ]]; then
            addProzessStatic "$prozess"
            elif [[ "$anweisung" == 'remove' ]]; then
            removeProzessStatic "$prozess"
        fi
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "dynamic" ]]; then
            addProzessDynamic "$prozess"
        fi
    done < example.txt
}

calculateNextHigherPowerOfTwo() {
    num=$1
    #Hier überprüfen wir, ob der Speicher bereits eine Zweierpotenz ist
    #Dabei wird der übergebene Speicher in bits umgewnadelt und durch das (num -1) invertiert
    #Beispiel num=8 1000  num -1 = 0111
    #Dann wird die invertierte Zahl mit der Originalzahl AND-verknüpft
    #Wenn das Ergebnis 0 ist, ist die Zahl eine Zweierpotenz
    if (( (num & (num - 1)) == 0 )); then
        echo $num
        return
    fi
    
    power=1
    #Ist der Speicher keine Zweierpotenz wird die übergebene Zahl solange durch 2 geteilt, bis sie größer als 1 ist,
    #um den Exponenten der nächst höheren Zweierpotenz zu finden
    while (( num > 1 )); do
        num=$((num / 2))
        ((power++))
    done
    #Die nächst höhere Zweierpotenz wird dann mithilfe des Exponenten potenziert
    potenz=$(echo "2^$power" | bc)
    echo $potenz
}

speicherverwaltung="dynamic"
dynamicKonzept="next"
matrixLaenge=""
lastindex=1

#Als erstes wird vom Benutzer die Speicherplatzgröße, sowie die Größe der Partitionen eingelesen
#Beide Werte werden auf die nächst höhere 2er Potenz gerundet
read -p "Geben Sie die Größe des Speicherplatzes ein: " speicherplatz

speicherplatzInPotenz=$(calculateNextHigherPowerOfTwo $speicherplatz)

if [[ "$speicherverwaltung" == "static" ]]; then
read -p "Geben sie die Größe der einzelnen Partitionen ein: " partition

partitionsgroeseInpotenz=$(calculateNextHigherPowerOfTwo $partition)

#Die Anzahl der Partitionen wir hier ausgrechnet, indem wir den gesamten Speicher (in Zweierpotenz) durch die partitionsgröße (in Zweierpotenz) teilen
matrixLaenge=$(expr $speicherplatzInPotenz / $partitionsgroeseInpotenz)
fi

if [[ $speicherverwaltung == "dynamic" ]];then
    matrixLaenge=$potenzSpeicher
fi

declare -A matrix

#Hier wird eine zweidimensionale Matrix definiert
#Bei der statischen Partitionierung ist die Länge der Matrix , also die Anzahl der Zeilen), gleich der Anzahl an Partitonen
#In der ersten Spalte wird i als Zähler hochgezählt um auf die Prozesse später zugreifen zu können
#und in der zweiten Spalte speichern wir die zugewiesenen Prozesse
for ((i=1; i<=matrixLaenge; i++)); do
    matrix[$i,1]=$i
    matrix[$i,2]=""
done

#In dieser Methode wwerden die Prozesse über eine .txt Datei eingelesen und Prozesse erstellt bzw. terminiert
readFile

#Mit Hilfe einer for-Schelife wird die Matrix am Ende ausgegeben
for ((i=1; i<=matrixLaenge; i++)); do
    for ((j=1; j<=2; j++)); do
        echo -n "${matrix[$i,$j]} "
    done
    echo
done

