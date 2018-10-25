using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneControllerEndless : MonoBehaviour {
    [SerializeField] private GameObject[] LevelSections;
    [SerializeField] private GameObject startLevel;
	[SerializeField] private AudioSource music;
	[SerializeField] private GameObject player;
    [SerializeField] public AudioClip[] songs;
    [SerializeField] public float[] speed;
    private float timePlayed;
    private int songNumber;
    private GameObject last, current, next;
	public int chunkSize = 16;
	public float center = -10f;
    private bool change = false;
    private bool firstChange = true;
    int newSongNum;

	// Use this for initialization
	void Start () {
        // Initialize a last part of level and current
        last = Instantiate(startLevel) as GameObject;
		last.transform.position = new Vector3(center, 0, 0);
		current = Instantiate(startLevel) as GameObject;
		current.transform.position = new Vector3(center+chunkSize, 0, 0);
		next = Instantiate(LevelSections[getRandomIndex(LevelSections.Length)]) as GameObject;
		next.transform.position = new Vector3(center +(chunkSize*2), 0, 0);
        songNumber = getRandomIndex(songs.Length);
        music.clip = songs[songNumber];
        music.time = 0f;
		music.Play();
	}
	
	void Update () {
		if (current.transform.position.x + (-speed[songNumber] * Time.deltaTime) >= center) {
			last.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
			current.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
			next.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
           
		} else {
			Destroy(last);
			last = current;
			current = next;
            timePlayed = Time.timeSinceLevelLoad;
            if (change)
            {
                while (newSongNum == songNumber)
                {
                    newSongNum = getRandomIndex(songs.Length);
                }
                songNumber = newSongNum;
                music.clip = songs[songNumber];
                music.time = 0;
                music.Play();
                if (firstChange)
                {
                    int x = 0;
                    float[] OGspeed = speed;
                    for (x = 0; x < speed.Length; x++)
                    {
                        speed[x] = speed[x] * 1.5f;
                    }
                    
                    firstChange = false;
                }
                change = false;
            }
            if (!music.isPlaying)
            {
                change = true;
                next = Instantiate(startLevel) as GameObject;
            } else
            {
                next = Instantiate(LevelSections[getRandomIndex(LevelSections.Length)]) as GameObject;
            }
            next.transform.position = new Vector3 (current.transform.position.x + chunkSize, 0, 0);
			last.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
			current.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
			next.transform.Translate (-speed[songNumber] * Time.deltaTime, 0, 0);
		}
		if (!player.GetComponent<PlayerCharacter>().alive && Input.GetButtonDown("Switch"))
			restart ();
	}
		       
	private int getRandomIndex(int arrLength) {
		float rand = Random.value;
		if(rand == 1)
			rand = Random.value;
		return (int) (rand*arrLength);
	}

    public void restart()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

    public void mainMenu()
    {
        GameControl.control.Save();
        SceneManager.LoadScene("Main Menu");
    }
		

}
