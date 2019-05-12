using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterController : MonoBehaviour
{
    Renderer rend;

    float fog;
    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
        rend.material.shader = Shader.Find("Custom/Water");
    }

    // Update is called once per frame
    void Update()
    {
        float fogChange = Input.GetAxis("Vertical") * .02f;
        fog = rend.material.GetFloat("_WaterFogDensity");
        fog += fogChange;
        if (fog < 0)
            fog = 0;
        else if (fog > 2)
            fog = 2;
        rend.material.SetFloat("_WaterFogDensity", fog);

        if (Input.GetButtonDown("Fire1"))
        {
            if (rend.material.GetFloat("_FlowStrength") == .1f)
                rend.material.SetFloat("_FlowStrength", 0);
            else
                rend.material.SetFloat("_FlowStrength", .1f);
        }
    }
}
