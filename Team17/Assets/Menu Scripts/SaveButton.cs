using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SaveButton : MonoBehaviour {

    [SerializeField] public Material BASE;
    [SerializeField] public Material LIGHT;

    private void OnMouseDown()
    {
        GameControl.control.Save();
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
