import java.io.File;
import java.io.PrintWriter;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

class LeaderboardEntry {
  String name;
  int missionID;
  float score;

  LeaderboardEntry(String name, int missionID, float score) {
    this.name = name;
    this.missionID = missionID;
    this.score = score;
  }
}

class LeaderboardManager {
  ArrayList<LeaderboardEntry> entries;
  String filePath;

  LeaderboardManager(String filePath) {
    this.filePath = filePath;
    this.entries = new ArrayList<LeaderboardEntry>();
    load();
  }

  void load() {
    entries.clear();
    try {
      File file = new File(filePath);
      if (!file.exists()) {
        // Create default leaderboard
        file.getParentFile().mkdirs();
        PrintWriter pw = new PrintWriter(file);
        pw.println("EVA,1,8500");
        pw.println("BRU,2,7800");
        pw.println("VAL,3,7200");
        pw.println("SAR,4,6500");
        pw.println("ALI,5,9000");
        pw.close();
      }

      BufferedReader br = new BufferedReader(new FileReader(file));
      String line;
      while ((line = br.readLine()) != null) {
        line = line.trim();
        if (line.length() == 0) continue;
        String[] parts = split(line, ',');
        if (parts.length >= 3) {
          String name = parts[0].toUpperCase();
          int mID = int(parts[1]);
          float sc = float(parts[2]);
          entries.add(new LeaderboardEntry(name, mID, sc));
        }
      }
      br.close();
      sortEntries();
    } catch (Exception e) {
      println("Error loading leaderboard: " + e.getMessage());
    }
  }

  void save() {
    try {
      File file = new File(filePath);
      file.getParentFile().mkdirs();
      PrintWriter pw = new PrintWriter(file);
      for (LeaderboardEntry e : entries) {
        pw.println(e.name + "," + e.missionID + "," + int(e.score));
      }
      pw.close();
    } catch (Exception e) {
      println("Error saving leaderboard: " + e.getMessage());
    }
  }

  void addEntry(String name, int missionID, float score) {
    name = name.toUpperCase();
    if (name.length() > 3) name = name.substring(0, 3);
    if (name.length() == 0) name = "AAA";
    entries.add(new LeaderboardEntry(name, missionID, score));
    sortEntries();
    
    // Keep top 10 entries max
    while (entries.size() > 10) {
      entries.remove(entries.size() - 1);
    }
    save();
  }

  void sortEntries() {
    Collections.sort(entries, new Comparator<LeaderboardEntry>() {
      public int compare(LeaderboardEntry e1, LeaderboardEntry e2) {
        return Float.compare(e2.score, e1.score); // descending order
      }
    });
  }

  ArrayList<LeaderboardEntry> getTop(int n) {
    ArrayList<LeaderboardEntry> top = new ArrayList<LeaderboardEntry>();
    for (int i = 0; i < min(n, entries.size()); i++) {
      top.add(entries.get(i));
    }
    return top;
  }
}
