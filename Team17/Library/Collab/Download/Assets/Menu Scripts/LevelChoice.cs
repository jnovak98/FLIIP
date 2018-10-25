using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelChoice : MonoBehaviour {
    [SerializeField] public Material RBase;
    [SerializeField] public Material RLight;
    [SerializeField] public Material BBase;
    [SerializeField] public Material BLight;
    [SerializeField] public int ButtonNumber;

    Material BASE;
    Material LIGHT;
    // Use this for initialization
    void Start () {
		if (GameControl.control.unlocks[ButtonNumber - 1])
        {
            BASE = BBase;
            LIGHT = BLight;
        } else
        {
            BASE = RBase;
            LIGHT = RLight;
        }
        Renderer rend = GetComponent<Renderer>();
        rend.material = BASE;
    }

    private void OnMouseDown()
    {
        if (GameControl.control.unlocks[ButtonNumber - 1]) {
            SceneManager.LoadScene(ButtonNumber);
        }
        
    }

    private void OnMouseOver()
    {
        Renderer rend = GetComponent<Renderer>();
        rend.material = LIGHT;
    }

    private void OnMouseExit()
    {
        Renderer rend = GetComponent<Renderer>();
        rend.material = BASE;
    }

}
