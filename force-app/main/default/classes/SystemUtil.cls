public with sharing class SystemUtil implements Queueable{
    public SystemUtil(){
        System.debug('Queueable created');
    }

    public Id enqueueJob(Queueable job){
        return System.enqueueJob(job);
    }

    public void execute(QueueableContext context) {
        System.debug('Queueable ran');
    }
}