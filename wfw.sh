#!/bin/bash
 
if [[ "$1" && -f "$1" ]]; then
    FILE="$1"
else
    echo 'Вкажіть .csv файл, який ви хочете проаналізувати.';
    echo 'Приклад запуску:';
    echo -e "\tbash wfw.sh /tmp/test-01.csv";
    exit   
fi
 
echo -e "\033[1mВсього точок доступу: \033[0;31m`grep -E '([A-Za-z0-9._: @\(\)\\=\[\{\}\"%;-]+,){14}' $FILE | wc -l`\e[0m"
echo -e "\033[1mВсього клієнтів: \033[0;31m`grep -E '([A-Za-z0-9._: @\(\)\\=\[\{\}\"%;-]+,){5} ([A-Z0-9:]{17})|(not associated)' $FILE | wc -l`\e[0m"
echo -e "\033[1mЗ них клієнтів без асоціації: \033[0;31m`grep -E '(not associated)' $FILE | wc -l`\e[0m"
 
echo -e "\033[0;36m\033[1mІнформація про мережі:\e[0m"
 
while read -r line ; do
 
    if [ "`echo "$line" | cut -d ',' -f 14`" != " " ]; then
        echo -e "\033[1m" `echo -e "$line" | cut -d ',' -f 14` "\e[0m"
    else
        echo -e " \e[3mНе вдалось отримати ім’я мережі\e[0m"
    fi
 
    fullMAC=`echo "$line" | cut -d ',' -f 1`
    echo -e "\tMAC-адреса: $fullMAC"
 
    MAC=`echo "$fullMAC" | sed 's/ //g' | sed 's/-//g' | sed 's/://g' | cut -c1-6`
 
    result="$(grep -i -A 1 ^$MAC ./oui.txt)";
  
    if [ "$result" ]; then
        echo -e "\tВиробник: `echo "$result" | cut -f 3`"
    else
        echo -e "\tВиробник: \e[3mІнформація не знайдена в базі даних.\e[0m"
    fi
 
    is5ghz=`echo "$line" | cut -d ',' -f 4 | grep -i -E '36|40|44|48|52|56|60|64|100|104|108|112|116|120|124|128|132|136|140'`
 
    if [ "$is5ghz" ]; then
        echo -e "\t\033[0;31mПрацює на 5 ГГц!\e[0m"
    fi
 
    printonce="\tІнформація про підключених клієнтів:"
 
    while read -r line2 ; do
 
        clientsMAC=`echo $line2 | grep -E "$fullMAC"`
        if [ "$clientsMAC" ]; then
 
            if [ "$printonce" ]; then
                echo -e $printonce
                printonce=''
            fi
 
            echo -e "\t\t\033[0;32m" `echo $clientsMAC | cut -d ',' -f 1` "\e[0m"
            MAC2=`echo "$clientsMAC" | sed 's/ //g' | sed 's/-//g' | sed 's/://g' | cut -c1-6`
 
            result2="$(grep -i -A 1 ^$MAC2 ./oui.txt)";
  
            if [ "$result2" ]; then
                echo -e "\t\t\tВиробник: `echo "$result2" | cut -f 3`"
                ismobile=`echo $result2 | grep -i -E 'Olivetti|Sony|Mobile|Apple|Samsung|HUAWEI|Motorola|TCT|LG|Ragentek|Lenovo|Shenzhen|Intel|Xiaomi|zte'`
                warning=`echo $result2 | grep -i -E 'ALFA|Intel'`
                if [ "$ismobile" ]; then
                    echo -e "\t\t\t\033[0;33mЙмовірно, це мобільний пристрій\e[0m"
                fi
 
                if [ "$warning" ]; then
                    echo -e "\t\t\t\033[0;31;5;7mПристрій може підтримувати режим монітора\e[0m"
                fi
 
            else
                echo -e "\t\t\tВиробник: \e[3mІнфомація не знайдена в базі даних.\e[0m"
            fi
 
            probed=`echo $line2 | cut -d ',' -f 7`
 
            if [ "`echo $probed | grep -E [A-Za-z0-9_\\-]+`" ]; then
                echo -e "\t\t\tТД, до яких він був підключений: $probed"
            fi         
        fi
    done < <(grep -E '([A-Za-z0-9._: @\(\)\\=\[\{\}\"%;-]+,){5} ([A-Z0-9:]{17})|(not associated)' $FILE)
     
done < <(grep -E '([A-Za-z0-9._: @\(\)\\=\[\{\}\"%;-]+,){14}' $FILE)
 
echo -e "\033[0;36m\033[1mІнформація про непідключених клієнтів:\e[0m"
 
while read -r line2 ; do
 
    clientsMAC=`echo $line2  | cut -d ',' -f 1`
 
    echo -e "\033[0;31m" `echo $clientsMAC | cut -d ',' -f 1` "\e[0m"
    MAC2=`echo "$clientsMAC" | sed 's/ //g' | sed 's/-//g' | sed 's/://g' | cut -c1-6`
 
    result2="$(grep -i -A 1 ^$MAC2 ./oui.txt)";
 
    if [ "$result2" ]; then
        echo -e "\tВиробник: `echo "$result2" | cut -f 3`"
        ismobile=`echo $result2 | grep -i -E 'Olivetti|Sony|Mobile|Apple|Samsung|HUAWEI|Motorola|TCT|LG|Ragentek|Lenovo|Shenzhen|Intel|Xiaomi|zte'`
        warning=`echo $result2 | grep -i -E 'ALFA|Intel'`
        if [ "$ismobile" ]; then
            echo -e "\t\033[0;33mЙмовірно, це мобільний пристрій\e[0m"
        fi
        if [ "$warning" ]; then
            echo -e "\t\033[0;31;5;7mПристрій може підтримувати режим монітора\e[0m"
        fi
    else
        echo -e "\tВиробник: \e[3mІнфомація не знайдена в базі даних.\e[0m"
    fi
 
    probed=`echo $line2 | cut -d ',' -f 7`
 
    if [ "`echo $probed | grep -E [A-Za-z0-9_\\-]+`" ]; then
        echo -e "\tТД, до яких він був підключений: $probed"
    fi         
 
done < <(grep -E '(not associated)' $FILE)
