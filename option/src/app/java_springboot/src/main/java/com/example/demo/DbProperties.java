package com.example.demo;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "db")
public class DbProperties {

        private String info;	

        public String getInfo() {
                return info;
        }
        public void setInfo(String info) {
                this.info = info;
        }
}


