using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MenuController : MonoBehaviour
{

    [SerializeField] GameObject TopMenu;
    [SerializeField] GameObject LevelsMenu;
    [SerializeField] GameObject SettingsMenu;

    GameObject currentMenu;
    // Use this for initialization
    void Start()
    {
        currentMenu = Instantiate(TopMenu);

    }

    public void backToTop()
    {
        Destroy(currentMenu);
        currentMenu = Instantiate(TopMenu);
    }

    public void toLevels()
    {
        Destroy(currentMenu);
        currentMenu = Instantiate(LevelsMenu);
        GameObject score1 = GameObject.Find("Score 1 Text");
        GameObject score2 = GameObject.Find("Score 2 Text");
        GameObject score3 = GameObject.Find("Score 3 Text");
        GameObject score4 = GameObject.Find("Endless Score Text");
        score1.GetComponent<Text>().text = "" + GameControl.control.highScore[0];
        score2.GetComponent<Text>().text = "" + GameControl.control.highScore[1];
        score3.GetComponent<Text>().text = "" + GameControl.control.highScore[2];
        score4.GetComponent<Text>().text = "" + GameControl.control.highScore[3];
    }

    public void toSettings()
    {
        Destroy(currentMenu);
        currentMenu = Instantiate(SettingsMenu);
    }

}