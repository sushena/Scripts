import time

def hello(event, context):
    print("Second update")
    time.sleep(4)
    return "Hello-world"