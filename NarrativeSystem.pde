class NarrativeSystem {

  MissionScene mission;
  String currentObjective = "";

  NarrativeSystem(MissionScene mission) {
    this.mission = mission;
  }

  void startMission() {
    eva("EVA INICIADA...");
    eva("Se detectó una campaña de ciberacoso.");
    eva("Varios usuarios están siendo afectados.");
    eva("Necesitamos rastrear el origen del acoso.");
    currentObjective = "Investiga la propagación.";
  }

  void startTracingPhase() {
    eva("BFS nos permite analizar la propagación por niveles.");
    eva("Selecciona usuarios para rastrear el acoso.");
    currentObjective = "Encuentra el origen del acoso.";
  }

  void sourceFound() {
    mission.triggerAlert("ORIGEN IDENTIFICADO");
    eva("La cuenta agresora fue identificada.");
    eva("Debemos contener la propagación.");
    currentObjective = "Bloquea las rutas de propagación.";
  }

  void containmentPhase() {
    eva("Haz click derecho sobre las conexiones.");
    eva("Necesitamos frenar el daño.");
    currentObjective = "Contén la propagación.";
  }

  void missionFailed() {
    mission.triggerAlert("RED COLAPSADA");
    eva("Demasiados usuarios fueron afectados.");
  }

  void missionSuccess() {
    mission.triggerAlert("RED ESTABILIZADA");
    eva("La propagación principal fue detenida.");
    eva("Hoy evitamos que más usuarios fueran afectados.");
  }

  void eva(String msg) {
    mission.dialogueSystem.eva(msg);
  }
}
