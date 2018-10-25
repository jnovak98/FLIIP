using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;

public class GameControl : MonoBehaviour {

    public static GameControl control;

    public int[] highScore = new int[] { 0, 0, 0, 0 };
    public bool[] unlocks = new bool[] { true, false, false, false };

    void Awake()
    {
        if (control == null)
        {
            DontDestroyOnLoad(gameObject);
            control = this;
        } else if (control != this)
        {
            Destroy(gameObject);
        }    
    }
    
    public void Save()
    {
        BinaryFormatter bf = new BinaryFormatter();
        FileStream file = File.Create(Application.persistentDataPath + "/playerInfo.dat");

        PlayerData data = new PlayerData();
        data.highScore = highScore;
        data.unlocks = unlocks;

        bf.Serialize(file, data);
        file.Close();

    }

    public void Load()
    {
        if (File.Exists(Application.persistentDataPath + "/playerInfo.dat"))
        {
            BinaryFormatter bf = new BinaryFormatter();
            FileStream file = File.Open(Application.persistentDataPath + "/playerInfo.dat", FileMode.Open);
            PlayerData data = (PlayerData)bf.Deserialize(file);
            file.Close();

            highScore = data.highScore;
            unlocks = data.unlocks;
        }
    }

}

[Serializable]
class PlayerData
{
    public int[] highScore;
    public bool[] unlocks;
}
