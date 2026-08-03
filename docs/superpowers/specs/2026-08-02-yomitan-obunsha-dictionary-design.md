# Yomitan Obunsha Dictionary Replacement

Replace the third Yomitan dictionary, 小学館例解学習国語 第十二版, with the no-image Yomitan build of 旺文社国語辞典 第十一版. Keep all other dictionaries and their order unchanged.

Use the public Google Drive file `1WhJk0gsgL2z_A6cYqIB7185EZd5GPvxs`, store the downloaded archive in `japanese/yomitan/dictionaries/`, and update the manifest, active-profile settings export, sorter, tests, and restore documentation. The no-image build is intentional because the replacement is also a performance experiment.

Verification requires a valid Yomitan ZIP containing `index.json`, sorter tests passing, no remaining 小学館 references in active configuration, and the dictionary download/bootstrap checks passing.
