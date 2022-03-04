using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestCoroutine : MonoBehaviour
{
    public Material Material;

    // Start is called before the first frame update
    void Start()
    {
        float[] test = new[] {5.0f, 5.0f,5.0f,5.0f};
        // Material.SetFloat("_SelectCell1", 5.0f);
        // Material.SetFloat("_SelectCell2", 5.0f);
        Material.SetFloatArray("_SelectCelltest", test);
    }
}