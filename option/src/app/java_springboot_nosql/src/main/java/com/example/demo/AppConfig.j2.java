{%import"java.j2_macro"as m with context%}

package com.example.demo;

import oracle.nosql.driver.NoSQLHandleConfig;
import oracle.nosql.driver.Region;
import oracle.nosql.driver.iam.SignatureProvider;
import com.oracle.nosql.spring.data.config.AbstractNosqlConfiguration;
import com.oracle.nosql.spring.data.config.NosqlDbConfig;
import com.oracle.nosql.spring.data.repository.config.EnableNosqlRepositories;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import oracle.nosql.driver.kv.StoreAccessTokenProvider;

@Configuration
@EnableNosqlRepositories(basePackageClasses = Dept.class)
public class AppConfig extends AbstractNosqlConfiguration {  
    @Bean
    public NosqlDbConfig nosqlDbConfig() throws java.io.IOException {
        {{ m.nosql_connection() }}
        return new NosqlDbConfig(config);
    }
}
