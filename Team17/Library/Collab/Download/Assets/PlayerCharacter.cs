using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;
using UnityEngine.UI;


public class PlayerCharacter : MonoBehaviour {
    [System.Serializable] public class ScoreComment
    {
        public int threshold;
        public string comment;
    }
    [SerializeField] public Material RED;
    [SerializeField] public Material BLUE;
    [SerializeField] public GameObject DeathCanvas;
    [SerializeField] public GameObject ScoreLabel;
    [SerializeField] public GameObject CommentLabel;
    [SerializeField] public GameObject player;
    [SerializeField] public int levelNumber;
    private float pos;
    //private int collNumber = 0;
    public bool alive = true; //Flag to stop checking collisions once we've died (while scene is reloading). Stops double scene-reloads.
    private Rigidbody rb;
    //private float killThreshold = 0.05f; //Sets the minimum required force to kill the player. Can't be zero because of small imperfections in platform surfaces. Can't be too high because of weak collisions.
    //private bool dying = false; //Death process requires collision force to be maintained over at least two consecutive Updates() since bumps in platform surfaces only cause a 1-frame impulse. Helps ignore bumps.
    private float autoKillDepth = -10f; //Sets the y-position at which we assume the player fell off and should be instantly killed.
	private RaycastHit hit;
	public int jumpVel = 10;
	public float gravity = -9.814f;
    //private int colCount = 0;

    // Use this for initialization
    void Start ()
    {
		Physics.gravity = new Vector3(0, gravity, 0);
        //Hide the UI that shows when you're dead
        rb = GetComponent<Rigidbody>();
        Renderer rend = GetComponent<Renderer>();
        if (this.transform.position.z == -0.5)
        {
			rend.material = BLUE;
            pos = -0.5f;
        }
        else
        {
			rend.material = RED;
            pos = 0.5f;
        }
    }
	

	
	// Update is called once per frame
	void Update () {
        //For some reason, using the built-in Freeze Position / Rotation functionality in Unity is causing the collisions to no longer be detected properly. So I'm doing it manually here.
        this.transform.position = new Vector3(-1f, this.transform.position.y, pos);
        this.transform.rotation = new Quaternion(0, 0, 0, 0);
        Ray downRay = new Ray(this.transform.position, Vector3.down);
        Ray rightRay = new Ray(this.transform.position, Vector3.right);
        bool down = Physics.Raycast(downRay, 0.1f);
        bool right = Physics.Raycast(rightRay, 0.1f);
        if (down)
        {
            this.transform.position = new Vector3(this.transform.position.x, this.transform.position.y);
        }
        else if (right)
        {
            kill();
        }
        bool s = Input.GetButtonDown("Switch");
        bool jumping = Input.GetButtonDown("Jump");
        for (int i = 0; i < Input.touchCount; i++)
        {
            if (Input.GetTouch(i).phase == TouchPhase.Began)
            {
                if (Input.GetTouch(i).position.x >= (Screen.width / 2))
                {
                    s = true;
                }
                else
                {
                    jumping = true;
                }
            }
        }
        if (alive && s)
        {
            pos = -pos;
            Renderer rend = GetComponent<Renderer>();
            this.transform.position = new Vector3(-1f, this.transform.position.y, pos);
            if (pos == -0.5)
            {
				rend.material = BLUE;
            }
            else
            {
                rend.material = RED;
            }
        }
        if (alive && jumping)
        {
            bool canJump = (Physics.Raycast(new Ray(transform.position - (new Vector3(0.3f, 0f, 0f)), -0.2f * transform.up), out hit, 1F) || Physics.Raycast(new Ray(transform.position + (new Vector3(0.3f, 0f, 0f)), -0.2f * transform.up), out hit, 1F));
            // canJump check at the front and back of the cube
            if (canJump) { //got rid of acceleration check: (rb.velocity.y < 0.2 && rb.velocity.y > -0.2)
                rb.velocity = new Vector3(rb.velocity.x, jumpVel, rb.velocity.z);
            }
		}

        
        //If the player is below the autoKillDepth, we assume they fell off the platform and instantly kill them.
        if (this.transform.position.y < autoKillDepth)
        {
            kill();
        }
	}

    //void OnCollisionEnter(Collision collision)
    //{
    //    attemptKill(collision);
    //    colCount++;
    //    Debug.Log("Collision Entered " + colCount);
    //}

    //void OnCollisionStay(Collision collision)
    //{
    //    attemptKill(collision);
    //}

    //void attemptKill(Collision collision)
    //{
    //    if (Mathf.Abs(collision.impulse.x) > killThreshold)
    //    {
    //        if (alive)
    //        {
    //            if (!dying)
    //            {
    //                dying = true;
    //            }
    //            else
    //            {
    //                kill();
    //            }
    //        }
    //    }
    //    else
    //    {
    //        dying = false;
    //    }
    //}

    void kill()
    {
        if (alive)
        {
            float timePlayed = Time.timeSinceLevelLoad;
            alive = false;
            DeathCanvas.SetActive(true);
            float score = Mathf.Floor(Mathf.Pow(timePlayed * 100f, 1.1f));
            if ((int) score > GameControl.control.highScore[levelNumber - 1])
            {
                GameControl.control.highScore[levelNumber - 1] = (int)score;
            }
            ScoreLabel.GetComponent<Text>().text = "" + score;
            if (timePlayed >= 60f && levelNumber < 4)
            {
                CommentLabel.GetComponent<Text>().text = "Congrats, you have unlocked the next level! Played for: " + (int) timePlayed + " seconds";
                GameControl.control.unlocks[levelNumber] = true;
            } else if (timePlayed < 60f && levelNumber < 4)
            {
                CommentLabel.GetComponent<Text>().text = "Nice try! Need to survive for " + ((int) (60f - timePlayed)) + " more seconds!"; 
            } else if (levelNumber == 4)
            {
                CommentLabel.GetComponent<Text>().text = "Nicely Done, you made it " + (int) timePlayed + " seconds!";
            }
            player.SetActive(false); 	
        }
    }
}
