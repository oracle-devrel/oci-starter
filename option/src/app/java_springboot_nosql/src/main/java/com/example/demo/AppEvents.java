package com.example.demo;

import com.zetcode.bean.TimeResponse;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class AppEvents {
    @EventListener(ApplicationReadyEvent.class)
    public void startApp(DemoRepository repository) {
        try {
            System.out.println("Preloading " + repository.save(new Dept(10, "ACCOUNTING", "BRUSSELS")));
            System.out.println("Preloading " + repository.save(new Dept(20, "RESEARCH", "SPRING NOSQL")));
            System.out.println("Preloading " + repository.save(new Dept(30, "SALES", "ROME")));
            System.out.println("Preloading " + repository.save(new Dept(40, "OPERATIONS", "MADRID")));    
        } catch (Exception e ) {
            System.err.println("Exception:" + e.getMessage());
            e.printStackTrace();
        }              
    }
}