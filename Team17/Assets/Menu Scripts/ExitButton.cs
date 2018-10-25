using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class ExitButton : MonoBehaviour {

    [SerializeField] public Material BASE;
    [SerializeField] public Material LIGHT;
    private void OnMouseDown()
    {
        Application.Quit();
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
