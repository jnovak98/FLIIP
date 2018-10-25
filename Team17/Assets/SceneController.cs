using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Audio;


public class SceneController : MonoBehaviour {
    [SerializeField] private GameObject[] easierLevelSections;
    [SerializeField] private GameObject[] harderLevelSections;
    [SerializeField] private GameObject startLevel;
	[SerializeField] private AudioSource music;
	[SerializeField] private float[] startTimes;
	[SerializeField] private GameObject player;
    private AudioClip song;
    private float timePlayed;
    private GameObject last, current, next;
    public float speed = 2.0f;
	public int chunkSize = 16;
	public float center = -8f;

	// Use this for initialization
	void Start () {
        // Initialize a last part of level and current
        last = Instantiate(startLevel) as GameObject;
		last.transform.position = new Vector3(center, 0, 0);
		current = Instantiate(startLevel) as GameObject;
		current.transform.position = new Vector3(center+chunkSize, 0, 0);
		next = Instantiate(easierLevelSections[getRandomIndex(easierLevelSections.Length)]) as GameObject;
		next.transform.position = new Vector3(center +(chunkSize*2), 0, 0);
		music.time = startTimes [getRandomIndex (startTimes.Length)];
		music.Play();
	}
	
	void Update () {
		if (current.transform.position.x + (-speed * Time.deltaTime) >= center) {
			last.transform.Translate (-speed * Time.deltaTime, 0, 0);
			current.transform.Translate (-speed * Time.deltaTime, 0, 0);
			next.transform.Translate (-speed * Time.deltaTime, 0, 0);
		} else {
			Destroy(last);
			last = current;
			current = next;
            timePlayed = Time.timeSinceLevelLoad;
            if (timePlayed <= 60f)
            {
                if (Random.Range(0.0f, 100.0f) < ((-1.5f * timePlayed) + 95f)) {
                    next = Instantiate(easierLevelSections[getRandomIndex(easierLevelSections.Length)]) as GameObject;
                } else
                {
                    next = Instantiate(harderLevelSections[getRandomIndex(harderLevelSections.Length)]) as GameObject;
                }
            } else
            {
                if (Random.Range(0.0f, 100.0f) < 75f)
                {
                    next = Instantiate(harderLevelSections[getRandomIndex(harderLevelSections.Length)]) as GameObject;
                } else
                {
                    next = Instantiate(easierLevelSections[getRandomIndex(easierLevelSections.Length)]) as GameObject;
                }
            }
			next.transform.position = new Vector3 (current.transform.position.x + chunkSize, 0, 0);
			last.transform.Translate (-speed * Time.deltaTime, 0, 0);
			current.transform.Translate (-speed * Time.deltaTime, 0, 0);
			next.transform.Translate (-speed * Time.deltaTime, 0, 0);
            if (!music.isPlaying)
            {
                music.time = 0;
                music.Play();
            }
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
