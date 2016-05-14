check_row() {
    #1 row; 2 mark; 3 board
    win=1
    line=$(head -n$(($row*2 + 2)) $3 | tail -n1)
    i=2
    while [ $i -lt 5 ]
    do
        field=$(echo "$line" | cut -d"|" -f$i)
        if [ "$field" != $2 ];then
            win=0
            break
        fi
        i=$(($i + 1))
    done
    echo $win
}

check_col() {
    #1 col; 2 mark; 3 board
    win=1
    c=$(cut -s -d"|" -f$(($1 + 2)) $3)
    i=1
    while [ $i -lt 4 ];do
        field=$(echo "$c" | head -n$i | tail -n1)
        if [ "$field" != $2 ];then
            win=0
            break
        fi
        i=$(($i + 1))
    done
    echo "$win"
}

check_main_diag() {
    #1 row; 2 col; 3 mark; 4 board
    i=0
    win=1
    if [ $1 -ne $2 ];then
        win=0
    else
        while [ $i -lt 3 ];do
            line=$(head -n$(($i*2 + 2)) $4 | tail -n1)
            field=$(echo $line | cut -d"|" -f$(($i+2)))
            if [ "$field" != $3 ];then
                win=0
                break
            fi
            i=$(($i + 1))
        done
    fi
    echo "$win"
}

check_sec_diag() {
    #1 row; 2 col; 3 mark; 4 board
    i=0
    win=1
    if [ $(( $col + $row )) -ne 2 ];then
        win=0
    else
        while [ $i -lt 3 ];do
            line=$(head -n$(($i * 2 + 2)) $4 | tail -n1)
            field=$(echo $line | cut -d"|" -f$((4 - $i)))
            if [ "$field" != $3 ];then
                win=0
                break
            fi
            i=$(($i + 1))
        done
    fi
    echo "$win"
}

check_diags() {
    #1 row; 2 col; 3 mark; 4 board
    main=$(check_main_diag $1 $2 $3 $4)
    sec=$(check_sec_diag $1 $2 $3 $4)
    echo $(($main || $sec))
}

check_win() {
    #1 row; 2 col; 3 mark; 4 board
    winRow=$(check_row $1 $3 $4)
    winCol=$(check_col $1 $3 $4)
    winDiag=$(check_diags $1 $2 $3 $4)
    echo $(($winRow || $winCol || $winDiag))
}

put_mark() {
    #1 row; 2 col; 3 mark; 4 board
    h=$(head -n$(( $1 * 2 + 1)) $board)
    t=$(tail -n+$(( $1 * 2 + 3 )) $board)
    line=$(head -n$(($1*2 + 2)) $board | tail -n1)
    left=$(echo $line | cut -d"|" -f1-$(( $2 + 1)))
    right=$(echo $line | cut -d"|" -f$(( $2 + 3))-)
    newLine="$left|$3|$right"

    echo >> $4
    echo "$h" | tee $4
    echo "$newLine" | tee -a $4
    echo "$t" | tee -a $4
}

is_full() {
    #1 board
    f=$(grep "\|[XO]\|[XO]\|[XO]\|" $1 | wc -l) 
    if [ $f -eq 3 ];then
        echo 1
    else
        echo 0
    fi
}

is_free() {
    #1 row; 2 col; 3 board
    field=$(head -n$(( $1 * 2 + 2 )) $3 | tail -n1 | cut -d"|" -f$(($2 + 2)))
    if [ "$field" != " " ];then
        echo 0
    else
        echo 1
    fi
}
ai() {
    #1 board; 2 mark
    for i in $(seq 0 2);do
        for j in $(seq 0 2);do
            if [ $(is_free $i $j $1) -eq 1 ];then
                echo "$i $j $2" >> f
                f=$(put_mark $i $j $2 $1)
                x=$(check_win $i $j "X" $1)
                o=$(check_win $i $j "O" $1)
                if [ $x -eq 1 ];then
                    echo 0
                elif [ $o -eq 1 ];then
                    echo 1
                else
                    if [ $(is_full $1) ];then
                        echo 0.5
                    else
                        if [ $2 = "X" ];then
                            m="O"
                        else
                            m="X"
                        fi
                        echo $(ai $1 $m)
                        #cp $1 "$(date +%s%N)"
                        f=$(put_mark $i $j " " $1)
                    fi
                fi
            fi  
        done
    done
}

#===========Create Dir================
if ! [ -d .tic-tac-toe ];then
    mkdir .tic-tac-toe
fi
#====================================
#=======Enter player Names===========
echo "Enter player one name - X"
read player1

echo "Enter player two name - O"
read player2

echo "$player1 vs. $player2"
#====================================
#=========Log file===================
name="$player1-$player2-$(date +%s)"
filepath=".tic-tac-toe/$name.log"
touch $filepath
#====================================
#========Board file==================
board="./$name-board.tmp"

i=0
echo "-------" >> $board
while [ $i -lt 3 ]
do
    echo "| | | |" >> $board
    echo "-------" >> $board
    i=$(expr $i + 1)
done
#    echo -e "Something\n"

#=====================================================================
#====================Moves=============================================
movesCnt=0
player=$player1
mark="X"
playerFlag=0
while [ $movesCnt -lt 9 ]
do
    #=========================PLAYER 1==================================================
    #=================Player1 validation===============================
    isPositionValid=0
    while [ $isPositionValid -ne 1 ];do
        echo "$player make your move - (row,col)"
        read playerMove
        isPositionValid=$(echo $playerMove | grep "([0-2],[0-2])" | wc -l) 
        if [ $isPositionValid -eq 1 ];then
            row=$(expr substr $playerMove 2 1)
            col=$(expr substr $playerMove 4 1)
            if [ $(is_free $row $col $board) -eq 0 ];then
                echo "This field is already taken!"
                isPositionValid=0
            fi
        else
            echo "Wrong input!"
        fi
    done
    #==================================================================
    #========================Create new board==========================

   
    put_mark $row $col $mark $board 


    echo "$player - $playerMove">>$filepath
    if [ $(check_win $row $col $mark $board) -eq 1 ];then
        echo "$player wins" | tee -a $filepath
        break
    fi

    playerFlag=$(( $playerFlag ^ 1))
    if [ $playerFlag -eq 0 ];then
        player=$player1
        mark="X"
    else
        player=$player2
        mark="O"
        echo $(ai $board $mark)
    fi
    movesCnt=$(($movesCnt + 1))
done

if [ $movesCnt -eq 9 ];then
    echo "Even" >> $filepath
fi

rm $board
