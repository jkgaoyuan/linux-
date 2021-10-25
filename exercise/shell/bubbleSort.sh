# 冒泡排序
#!/bin/bash
#定义数组
arry=(9 4 5 6 8 3)
#echo  ${#arry[*]}  #获取数组长度  arry[*] 表示数组中的所有元素
for (( i = 1; i < ${#arry[*]}; i++ )); do  #控制比较循环次数， 次数为数组长度-1
  for (( j = 0; j < ${#arry[*]}-i ; j++ )); do   #比较次数随着比较轮数减少
      if [  ${arry[$j]} -gt  ${arry[$[$j+1]]} ]; then #如果第一个元素大于第二个元素就进行互换
          tpm=${arry[$j]}
          arry[$j]=${arry[$[$j+1]]}
          arry[$[$j+1]]=$tpm
      fi

  done

done

echo ${arry[*]} #输出完成后的数组

