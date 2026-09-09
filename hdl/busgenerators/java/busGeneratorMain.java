import javax.swing.JFrame;

/*
 * Whisbone bus generator
 * Copyright by T.J.H. Kluter
 *
 * https://https://github.com/logisim-evolution/riscV_edu_platform
 * 
 */

public class busGeneratorMain {
  public static void main(String[] args) {
    JFrame frame = new busGeneratorFrame();
    frame.setSize(640,480);
    frame.setLocationRelativeTo(null);
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.setVisible(true);
  }
}
