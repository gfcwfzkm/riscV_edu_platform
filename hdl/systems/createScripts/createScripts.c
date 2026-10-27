#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#define ModulesDirectory "../../modules/"
#define ModulesFile "modules.txt"
#define ScriptDirectory "scripts/"
#define VerilogFiles "filesVerilog.txt"
#define TopLevelNameFile "toplevel.txt"

#define maxLength 256
#define maxSourceFiles 2048

void removeNewLine( char* buffer ) {
  char *ptr = strstr(buffer, "\n");
  if (ptr != NULL)
    strncpy(ptr, "\0", 1);
}

void fileNotFound( char* fName , int cnt, char **sources) {
  printf("Unable to open the file \"%s\"!\nAborting....\n", fName);
  while (cnt > 0) {
    free(sources[--cnt]);
  }
}

int main () {
  FILE *modulesFile, *verilogFile;
  char buffer[maxLength], *fileName, *directoryName;
  char *sourceFiles[maxSourceFiles];
  char *toplevelName = NULL;
  int sourceCount = 0;
  struct stat st = {0};
  
  sprintf(buffer,"%s%s" , ScriptDirectory, ModulesFile);
  
  modulesFile = fopen(buffer, "r");
  if (modulesFile == NULL) {
    fileNotFound(buffer, sourceCount, sourceFiles);
    return -1;
  }
  
  while (fgets(buffer, maxLength, modulesFile)) {
    removeNewLine(buffer);
    if (strlen(buffer) != 0) {
      directoryName = (char *) malloc(strlen(ModulesDirectory)+strlen(buffer)+2);
      sprintf(directoryName, "%s%s/", ModulesDirectory, buffer);
      fileName = (char *)malloc(strlen(directoryName)+strlen(VerilogFiles)+strlen(ScriptDirectory)+2);
      sprintf(fileName, "%s%s%s", directoryName, ScriptDirectory, VerilogFiles);
      verilogFile = fopen(fileName, "r");
      if (verilogFile == NULL) {
        fileNotFound(fileName, sourceCount, sourceFiles);
        fclose(modulesFile);
        return -1;
      }
      while (fgets(buffer, maxLength, verilogFile)) {
        removeNewLine(buffer);
        if (strlen(buffer) != 0){
          if (sourceCount > maxSourceFiles) {
            printf("More than %d source files found, cannot create scripts!\nAborting....\n", maxSourceFiles);
            fclose(verilogFile);
            fclose(modulesFile);
            free(fileName);
            free(directoryName);
            while (sourceCount > 0) {
              free(sourceFiles[--sourceCount]);
            }
            return -1;
          }
          sourceFiles[sourceCount] = (char*) malloc(strlen(directoryName)+strlen(buffer)+4);
          sprintf(sourceFiles[sourceCount++], "../%s%s", directoryName, buffer);
        }
      }
      fclose(verilogFile);
      free(fileName);
      free(directoryName);
    }
  }
  fclose(modulesFile);
  /* we have now gathered all info on the used modules, now we only need the info of the top-level */
  
  sprintf(buffer, "%s%s", ScriptDirectory, VerilogFiles);
  modulesFile = fopen(buffer, "r");
  
  if (modulesFile == NULL) {
    fileNotFound(buffer, sourceCount, sourceFiles);
    return -1;
  }
  
  while (fgets(buffer, maxLength, modulesFile)) {
    removeNewLine(buffer);
    if (strlen(buffer) > 0) {
      if (sourceCount > maxSourceFiles) {
        printf("More than %d source files found, cannot create scripts!\nAborting....\n", maxSourceFiles);
        fclose(modulesFile);
        while (sourceCount > 0) {
          free(sourceFiles[--sourceCount]);
        }
        return -1;
      }
      sourceFiles[sourceCount] = (char*) malloc(strlen(buffer)+4);
      sprintf(sourceFiles[sourceCount++], "../%s", buffer);
    }
  }
  
  fclose(modulesFile);
  
  sprintf(buffer, "%s%s", ScriptDirectory, TopLevelNameFile );
  modulesFile = fopen(buffer , "r");
  
  if (modulesFile == NULL) {
    fileNotFound(buffer, sourceCount, sourceFiles);
    return -1;
  }
  
  while (fgets(buffer, maxLength, modulesFile)) {
    removeNewLine(buffer);
    if (strlen(buffer) > 0) {
      if (toplevelName != NULL) {
        printf("More than one toplevel name specified in \"%s%s\"!\n Cannot continue...\n", ScriptDirectory, TopLevelNameFile );
        fclose(modulesFile);
        free(toplevelName);
        while (sourceCount > 0) {
          free(sourceFiles[--sourceCount]);
        }
        return -1;
      }
      toplevelName = (char *) malloc(strlen(buffer)+1);
      sprintf(toplevelName, "%s", buffer );
    }
  }
  
  if (stat("sandbox", &st) == -1) {
    mkdir("sandbox", 0777);
  }
  
  modulesFile = fopen("sandbox/sim.sh", "w");
  if (modulesFile == NULL) {
    printf("Could not create file \"sandbox/sim.sh\"!\nAborting...\n");
    while (sourceCount > 0) {
      free(sourceFiles[--sourceCount]);
    }
    free(toplevelName);
    return -1;
  }
  
  printf("Creating modelsim/questasim simulation script\n");
  fprintf(modulesFile, "#/bin/bash\n");
  for (int i = 0 ; i < sourceCount; i++){
    fprintf(modulesFile, "vlog %s\n", sourceFiles[i]);
  }
  fprintf(modulesFile, "vsim -t ps %s\n", toplevelName );
  fclose(modulesFile);
  
   modulesFile = fopen("sandbox/yosys.script", "w");
  if (modulesFile == NULL) {
    printf("Could not create file \"sandbox/yosys.script\"!\nAborting...\n");
    while (sourceCount > 0) {
      free(sourceFiles[--sourceCount]);
    }
    free(toplevelName);
    return -1;
  }
  
  printf("creating yosys script for the GECKO5Education\n");
 
  for (int i = 0; i < sourceCount; i++) {
    fprintf(modulesFile, "read -sv %s\n", sourceFiles[i]);
  }
  fprintf(modulesFile, "synth_ecp5 -top %s -json %s.json\n", toplevelName, toplevelName );
  fclose(modulesFile);
  
    modulesFile = fopen("sandbox/synthesize.sh", "w");
  if (modulesFile == NULL) {
    printf("Could not create file \"sandbox/synthesize.sh\"!\nAborting...\n");
    while (sourceCount > 0) {
      free(sourceFiles[--sourceCount]);
    }
    free(toplevelName);
    return -1;
  }
  
  printf("creating synthesis script for the GECKO5Education\n");
  fprintf(modulesFile, "#/bin/bash\n");
  fprintf(modulesFile, "yosys -s yosys.script\n");
  fprintf(modulesFile, "nextpnr-ecp5 --threads 12 --timing-allow-fail --85k --package CABGA381 --json %s.json --lpf ../scripts/gecko5.lpf --textcfg %s.config\n", toplevelName, toplevelName);
  fprintf(modulesFile, "ecppack --compress --freq 62.0 --input %s.config --bit %s.bit\n", toplevelName, toplevelName);
  fclose(modulesFile);
 
 while (sourceCount > 0) {
    free(sourceFiles[--sourceCount]);
  }
  free(toplevelName);
}
