package me.opc.mp.database;

import java.util.*;
import java.util.stream.*;
import java.io.*;
import java.net.*;
import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

/**
 * Dept Table 
 */
@Path("/")
public class DeptResource {

    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() throws Exception {
        URL url = new URL("https://"+System.getenv("DB_URL")+":9200/dept/_search?size=1000&scroll=1m&pretty=true");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        if (conn.getResponseCode() != 200) {
            throw new RuntimeException("Error code : " + conn.getResponseCode());
        }
        BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));
        String body = br.lines().collect(Collectors.joining());
        conn.disconnect();

        List<Dept> d = new ArrayList<Dept>();
        JsonObject jsonObject = Json.createReader(new StringReader(body)).readObject();
        JsonArray hitsArray = jsonObject.getJsonObject("hits").getJsonArray("hits");   
        for (JsonObject hit : hitsArray.getValuesAs(JsonObject.class)) {
            JsonObject source = hit.getJsonObject("_source");
            d.add(new Dept(Integer.valueOf(source.getString("deptno")), source.getString("dname"), source.getString("loc") ));
        }
        return d;
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon / OpenSearch";
    }
}


