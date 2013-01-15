import threading
import urllib2
import urllib
import json

class Worker(threading.Thread):

    def __init__(self, work_queue, pm):
        #super(self).__init__()
        threading.Thread.__init__(self)
        self.work_queue = work_queue
        self.pm = pm
        
    def run(self):
        while True:
            try:
                request = self.work_queue.get()
              
                result = self.pm.invoke_processor_sql( 
                    request['access_token'], 
                    request['jsonParams'],
                    request['view_url']
                )
                
                if not(result is None):
                    url = request['result_url']
                    data = urllib.urlencode(json.loads(result))
                    req = urllib2.Request(url,data)
                    f = urllib2.urlopen(req)
                    response = f.read()
                    f.close()
                    print "sent worker response"
            except Exception, e:   
                print e
                    
            finally:
                #self.work_queue.task_done()
                print "done.."