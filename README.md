** /!\ Work in progress, this README needs to be completed. **

# Release Notes

## Version 1.5
* Based on [Deetazilla](https://github.com/Logimethods/deetazilla)

# Choix d'architecture**
1. Kubernetes
Dans la configuration précédente, Docker Swarm était utilisé pour déployer divers composants. Cependant, nous avons décidé de migrer vers Kubernetes pour plusieurs raisons convaincantes :
* Fonctionnalités avancées d'orchestration : Kubernetes offre un ensemble robuste de capacités, telles que :
  * Mise à l'échelle automatique.
  * Auto-réparation (redémarrage automatique des conteneurs échoués).
  * Meilleur support pour les applications complexes multi-conteneurs.
* Écosystème et support communautaire : Avec une communauté plus large et active, Kubernetes bénéficie :

   * D'une documentation étendue.
   * De nombreuses intégrations tierces.
   * D'un riche écosystème d'outils.
 * Outils clés dans l'écosystème Kubernetes :

  * Helm : Gestionnaire de packages pour les manifests Kubernetes, simplifiant le déploiement et la gestion des applications.

  * Prometheus : Collecte des métriques pour la surveillance et l'observabilité.

  * NGINX Ingress : Permet d'exposer les applications Kubernetes aux utilisateurs externes tout en gérant efficacement le trafic.

  * Istio : Une service mesh qui offre des fonctionnalités comme le chiffrement TLS pour sécuriser la communication entre services.

 * Sécurité et conformité : Kubernetes propose des configurations avancées et des fonctionnalités essentielles pour les environnements critiques en matière de sécurité et de conformité.

2. NATS
 * Objectif : Un système de messagerie léger et performant, conçu pour la communication en temps réel et les architectures de microservices.

 * Comparaison :

     * Kafka : Meilleur pour le streaming de messages à grande échelle et les architectures basées sur les événements, mais plus lourd et complexe à gérer.
     * RabbitMQ : Offre des fonctionnalités avancées de routage et de mise en file d'attente des messages, mais moins léger et rapide que NATS.
 *Pourquoi NATS ?
Choisi pour sa simplicité, sa faible latence (<1 ms), et son adéquation avec les scénarios nécessitant une communication rapide et éphémère sans persistance de messages à long terme.

3. Telegraf
* Objectif : Un agent piloté par des plugins pour collecter, traiter et reporter des métriques depuis divers systèmes, bases de données et applications.
* Comparaison :

    * Prometheus Node Exporter : Spécialisé dans l'exposition des métriques matérielles et OS, tandis que Telegraf prend en charge une large gamme de plugins pour diverses sources de données.
 * Pourquoi Telegraf ?
Choisi pour sa polyvalence, sa simplicité de configuration et son intégration avec des backends comme InfluxDB, Prometheus ou Graphite.

4. Graphite
5.  * Objectif : Une base de données de séries temporelles et un outil de visualisation pour la surveillance et l'analyse des performances.

 * Comparaison :

      * Prometheus : Propose des capacités de requêtes plus robustes (via PromQL) et des fonctionnalités d'alerte intégrées, mais Graphite excelle dans le stockage à long terme des métriques haute résolution.
       * InfluxDB : Plus moderne et riche en fonctionnalités, avec un langage de requêtes de type SQL, mais plus lourd à configurer.
 * Pourquoi Graphite ?
Choisi pour sa simplicité, sa scalabilité et sa réputation dans la visualisation des données de séries temporelles.

5. Gatling
 * Objectif : Un outil de test de performance pour simuler le trafic utilisateur et évaluer les performances des applications.

 * Comparaison :

     * JMeter : Propose un ensemble de fonctionnalités plus large et une interface graphique, mais Gatling est plus efficace pour gérer des charges importantes grâce à son approche asynchrone basée sur le code.
     * Locust : Basé sur Python, mieux adapté pour des scripts de tests personnalisés, mais Gatling offre un système de rapports plus complet et une meilleure scalabilité pour les tests à grande échelle.
 * Pourquoi Gatling ?
Choisi pour son puissant DSL pour définir les scénarios, ses rapports HTML détaillés et son efficacité pour tester les systèmes complexes.

6. Cassandra
Nous sommes passés d'une architecture traditionnelle master-slave à l'architecture native masterless de Cassandra, permettant une scalabilité horizontale sans point de défaillance unique. Cette transition s'intègre parfaitement aux fonctionnalités de scalabilité de Kubernetes.

 * Ces améliorations garantissent :

    * Une haute disponibilité grâce à la réplication des données entre les nœuds.
    * Une tolérance aux pannes renforcée en combinant les capacités d'orchestration de Kubernetes avec la conception résiliente de Cassandra.

<img src="images/SmartMeter.png" alt="SmartMeter Architecture" width="640x">

## Docker Run

```
  scripts> ./compose_classic.sh
```    

## Docker Compose

```
  > export docker_tag="1.5"
  > export NETWORK_NAME="smartmeter"
```    

* First, create your `docker-compose-merge.yml`:
    * When Docker Secrets are provided:    
    `docker run --rm logimethods/smart-meter:app_compose-${docker_tag} combine_services -e "local" "single" "secrets" root_metrics inject streaming_metrics prediction_metrics > docker-compose-merge.yml`
    * When Docker Secrets are NOT provided:    
    `docker run --rm logimethods/smart-meter:app_compose-${docker_tag} combine_services -e "local" "single" "no_secrets" root_metrics inject streaming_metrics prediction_metrics > docker-compose-merge.yml`
    * To make use of local properties:
    ```
    docker run --rm -v `pwd`/alt_properties:/templater/alt_properties logimethods/smart-meter:app_compose-${docker_tag} \
    combine_services -p alt_properties -e "local" "single" "no_secrets" root_metrics inject streaming_metrics prediction_metrics \
    > docker-compose-merge.yml
    ```
* Last, but not least, start the services based on the previously generated `docker-compose-merge.yml` file:
```
./docker-[local | remote]-[single | cluster]-up.sh
.../...
./docker-[local | remote]-down.sh
```
## Kubernetes

* Tout d'abord, créez les ConfigMaps et les Secrets nécessaires en utilisant :
  * Créez les ConfigMaps qui contiennent les scripts d'initialisation pour créer les keyspaces : `smart-meter/scripts/kubernetes/setup_cassandra_initscripts.sh`
  * Créez le Secret qui contiendra les identifiants pour accéder au serveur NATS : `smart-meter/scripts/kubernetes/create_kubernetes_nats_creds.sh`
* Ensuite, installez le chart Helm pour déployer les différents composants nécessaires en utilisant `helm install <release-name> helm/smart-meter`
  * Si vous avez besoin d'ajuster les configurations pour les différents déploiements, utilisez le fichier de valeurs : `helm/smart-meter/values.yaml`



## Python CLI

### Local

See [start-services.py](start-services.py)
```
> python3 -i ./start-services.py
>>> run_inject()
>>> run_app_batch()
...
>>> stop_all()
...
>>> exit()
```

Setup the Grafana Data Sources (see bellow) + Import [gatling + max voltage.json](dockerfile-app_metrics/gatling%20%2B%20max%20voltage.json)

[http://localhost/dashboard/db/gatling-max-voltage](http://localhost/dashboard/db/gatling-max-voltage)

![gatling-max-voltage_screenshot.png](images/gatling-max-voltage_screenshot.png "Gatling-max-voltage Screenshot")

In parallel, you can play with the number of injectors:
```
> docker service scale inject=2
> docker service scale inject=1
```

### Local (DEV mode)

```
> ./build_DEV.sh
> ./stop.sh
> python3 -i start-services.py "local" "single" "-DEV"
Images will be postfixed by -DEV
>>> run_inject()
```

### Remote (on Docker Swarm)

```
> ssh -NL localhost:2374:/var/run/docker.sock docker@xxxxx.amazonaws.com &
> python3 -i ./start-services.py "remote" "cluster"
> Remote Docker Client
>>> run_inject_cluster()
...
>>> stop_all()
...
>>> exit()
```

Setup the Grafana Data Sources (see bellow) + Import [gatling + max voltage - swarm.json](dockerfile-app_metrics/gatling%20%2B%20max%20voltage%20-%20swarm.json).

![gatling-max-voltage-swarm_screenshot.png](images/gatling-max-voltage-swarm_screenshot.png "Gatling-max-voltage-swarm Screenshot")

## Architectures
The *Injection* demo architecture:
![SmartMeter-Inject.png](images/SmartMeter-Inject.png "SmartMeter Injection Architecture")

The *Batch* demo architecture:

<img src="images/SmartMeter-Batch.png" alt="SmartMeter Injection Architecture" width="600x">

## Grafana Setup

/!\ To login to Grafana, use `admin` as the user, with the password defined by the `GF_SECURITY_ADMIN_PASSWORD` variable in the [configuration.properties](properties/configuration.properties#L98) file.

From [Grafana](http://localhost:80), setup the Graphite, InfluxDB & Prometheus Data Sources:
```
> ./import_grafana_datasources.sh [grafana_URL]
```

<img src="images/graphite_data_source.png" alt="Graphite Data Source" width="300x">
<img src="images/influxdb_data_source.png" alt="InfluxDB Data Source" width="300x">
<img src="images/prometheus_data_source.png" alt="Prometheus Data Source" width="300x">

## CQLSH (Cassandra CLI)
To access to the RAW Voltage Data:
```
> docker exec -it $(docker ps | grep cassandra-cluster-main | awk '{print $NF}' ) cqlsh
Connected to Smartmeter Cluster at 127.0.0.1:9042.
[cqlsh 5.0.1 | Cassandra 3.5 | CQL spec 3.4.0 | Native protocol v4]
Use HELP for help.
cqlsh> select * from smartmeter.raw_data limit 2;

line | transformer | usagepoint | year | month | day | hour | minute | day_of_week | demand | val10 | val11 | val12 | val3 | val4 | val5 | val6 | val7 | val8 | val9 | voltage
------+-------------+------------+------+-------+-----+------+--------+-------------+--------+-------+-------+-------+------+------+------+------+------+------+------+-----------
  11 |           2 |          5 | 2019 |     3 |  17 |   12 |     13 |           0 |    100 |    10 |    11 |    12 |    3 |    4 |    5 |    6 |    7 |    8 |    9 | 114.76842
  11 |           2 |          5 | 2019 |     3 |  17 |   11 |     58 |           0 |    100 |    10 |    11 |    12 |    3 |    4 |    5 |    6 |    7 |    8 |    9 | 114.10834
```

## Training & Predictions

![SmartMeter-Training.png](images/SmartMeter-Training.png "SmartMeter Training Architecture")

See [Multilayer perceptron classifier](http://spark.apache.org/docs/latest/ml-classification-regression.html#multilayer-perceptron-classifier) and [SparkPredictionProcessor.scala](dockerfile-app-streaming/src/main/scala/com/logimethods/nats/connector/spark/app/SparkPredictionProcessor.scala)
```
+-----+----------+----+--------------------+--------------------+---------+-----------+--------------------+----------+
|label|   voltage|hour|             hourSin|             hourCos|dayOfWeek|temperature|            features|prediction|
+-----+----------+----+--------------------+--------------------+---------+-----------+--------------------+----------+
|    0| 115.36195|  13| -12.940958284226115| -48.296289698960514|        0| -1.1098776|[-12.940958284226...|       0.0|
|    0|115.378006|  14| -24.999994594456457|   -43.3012733101135|        0|  16.545746|[-24.999994594456...|       0.0|
|    0|  116.9641|   3|   35.35533905932737|   35.35533905932738|        0|   4.004334|[35.3553390593273...|       0.0|
|    1| 118.92017|  23|  -12.94095828422611|  48.296289698960514|       50|  21.167358|[-12.940958284226...|       0.0|
|    1| 119.15324|  12|6.123233995736766...|               -50.0|       50| -12.110409|[6.12323399573676...|       1.0|
|    0|  115.1506|  14| -24.999994594456457|   -43.3012733101135|        0|  10.854811|[-24.999994594456...|       0.0|
|    0|115.264404|  14| -24.999994594456457|   -43.3012733101135|        0|  17.071587|[-24.999994594456...|       0.0|
.../...
|    1| 117.36004|   9|   35.35533905932738|  -35.35533905932737|       50|  -12.67373|[35.3553390593273...|       1.0|
|    1| 117.69681|  19|  -48.29628969896052|   12.94095828422609|       50|  17.909231|[-48.296289698960...|       0.0|
|    1|117.809166|  21| -35.355339059327385|   35.35533905932737|        0|   7.070238|[-35.355339059327...|       1.0|
|    0| 115.50017|  16|  -43.30127331011349|  -24.99999459445649|        0|  18.125008|[-43.301273310113...|       0.0|
+-----+----------+----+--------------------+--------------------+---------+-----------+--------------------+----------+
only showing top 20 rows

Test set accuracy = 0.9642857142857143
```

![grafana-predictions_screenshot.png](images/grafana-predictions_screenshot.png "Grafana Predictions Screenshot")

The generated ML Models are stored in HDFS (on port `50070`): [Browsing HDFS](http://localhost:50070/explorer.html#/smartmeter/voltage_prediction.model/)

## Additional Metrics

### NATS Metrics
Setup the Grafana Data Sources + Import [NATS Servers.json](dockerfile-app_metrics/NATS%20Servers.json).
![grafana_nats_screenshot.png](images/grafana_nats_screenshot.png "Grafana NATS Metrics Screenshot")

## Excel

### Install the ODBC Driver

* Get the Driver from http://www.simba.com/drivers/cassandra-odbc-jdbc/
* Follow the Installation Instructions (on MacOS, don't forget first to install [iODBC](http://www.iodbc.org/))
* Save the Licence file you received by Mail (`SimbaApacheCassandraODBCDriver.lic`) into the right location

### Create a SDN File

* Define a SDN file, such as [excel/cassandra.dsn](excel/cassandra.dsn)
* You could load & test it directly through the iODBC Administrator App:
![iODBC_test_sdn_file.png](excel/iODBC_test_sdn_file.png)

### Connect to the External Data from Excel using the `iODBC Data Source Chooser` (File DSN)

* You might use the SQL syntax, such as `select * from smartmeter.raw_data limit 10;`
* Et Voilà!

![from_Cassandra_2_Excel.png](excel/from_Cassandra_2_Excel.png)

# Build
## Legacy (local) build
```
/smart-meter/scripts > ./docker_build.sh dockerfile-app_streaming
```

## [Concourse](http://concourse.ci/) Continuous Integration

See [Concourse Pipeline](concourse/smart_meter-pipeline.yml).

![concourse_build.png](images/concourse_build.png "Concourse Build")

