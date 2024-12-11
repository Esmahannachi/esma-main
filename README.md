# Choix d'architecture
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

<img src="screenshot/Cassandra.drawio.png" alt="SmartMeter Architecture" width="640x">

L'architecture déployée sur Kubernetes est illustrée dans la figure ci-dessous, mettant en évidence la manière dont ces outils interagissent pour fonctionner ensemble efficacement.

<img src="screenshot/smart-meter.png" alt="SmartMeter Architecture" width="640x">

## Docker Run

```
  scripts> ./compose_classic.sh
```    

## Docker Compose

```
  > export docker_tag="1.5"
  > export NETWORK_NAME="smartmeter"
```    

* out d'abord, créez votre fichier `docker-compose-merge.yml`:
    * Lorsque les Docker Secrets sont fournis :    
    `docker run --rm logimethods/smart-meter:app_compose-${docker_tag} combine_services -e "local" "single" "secrets" root_metrics inject streaming_metrics prediction_metrics > docker-compose-merge.yml`
    * Lorsque les Docker Secrets ne sont PAS fournis :  
    `docker run --rm logimethods/smart-meter:app_compose-${docker_tag} combine_services -e "local" "single" "no_secrets" root_metrics inject streaming_metrics prediction_metrics > docker-compose-merge.yml`
    * Pour utiliser des propriétés locales :
    ```
    docker run --rm -v `pwd`/alt_properties:/templater/alt_properties logimethods/smart-meter:app_compose-${docker_tag} \
    combine_services -p alt_properties -e "local" "single" "no_secrets" root_metrics inject streaming_metrics prediction_metrics \
    > docker-compose-merge.yml
    ```
* Enfin, démarrez les services en utilisant le fichier  `docker-compose-merge.yml` file:
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

## Les captures d'écran ci-dessus proviennent de Grafana

<img src="screenshot/Screenshot 2024-12-08 234625.png" alt="SmartMeter Architecture" width="640x">
<img src="screenshot/Screenshot 2024-12-08 234817.png" alt="SmartMeter Architecture" width="640x">
<img src="screenshot/Screenshot 2024-12-08 231444.png" alt="SmartMeter Architecture" width="640x">
