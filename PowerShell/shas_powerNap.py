import time
import winsound
frequency = 2500
duration = 5000

for i in range(0,599):
  print(i)
  time.sleep(1)
winsound.Beep(frequency, duration)
