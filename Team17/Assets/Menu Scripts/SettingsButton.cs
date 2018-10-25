﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SettingsButton : MonoBehaviour {

    [SerializeField] public Material BASE;
    [SerializeField] public Material LIGHT;
    GameObject menuController;

    private void Start()
    {
        menuController = GameObject.Find("Menu Controller");
    }
    private void OnMouseDown()
    {
        menuController.SendMessage("toSettings");
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
