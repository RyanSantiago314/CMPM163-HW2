using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class TerrainGenerator : MonoBehaviour 
{
	public Terrain terrain;
	public int heightScale = 70;

	private int edgeSize = 256;

	[Range(1, 6)]
	public int octaves = 2;

	[Range(0f, 10f)]
	public float noiseXstart = 0f;
	[Range(0f, 10f)]
	public float noiseYstart = 0f;

	[Range(0f, 5f)]
	public float noiseXspan = 5f;
	[Range(0f, 5f)]
	public float noiseYspan = 5f;

	[Range(0.01f, 1f)]
	public float persistence = .25f;

	private float[,] heightField;
	float[,,] splatmapData;

	public Texture2D goalTexture;

	[Range(.01f, 1f)]
	public float mixFraction = .5f;

	public int numTrees = 100;


	void Start()
	{
        noiseXstart = Random.Range(0f, 10f);
        noiseYstart = Random.Range(0f, 10f);
        noiseXspan = Random.Range(7f, 10f);
        noiseYspan = Random.Range(7f, 10f);
        terrain = GetComponent<Terrain>();

		heightField = new float[edgeSize, edgeSize];

		PlaceTreesAcrossTerrain(numTrees);

		GenerateTerrainGuidanceTexture(terrain.terrainData, goalTexture, mixFraction);
		AssignSplatMap(terrain.terrainData);
	}
	void Update()
	{
	}

	TerrainData GenerateTerrainGuidanceTexture (TerrainData terrainData, Texture2D guideTexture, float mixFraction)
	{
		terrainData.heightmapResolution = edgeSize;
		terrainData.size = new Vector3(edgeSize, heightScale, edgeSize);

		GenerateHeightGuidanceTexture(guideTexture, mixFraction);
		terrainData.SetHeights(0, 0, heightField);

		return terrainData;
	}

	void GenerateHeightGuidanceTexture(Texture2D guideTexture, float mixFraction)
	{
		for (int i = 0; i < edgeSize; i++)
		{
			for (int j = 0; j < edgeSize; j++)
			{
				heightField[j, i] = CalculateHeightGuidanceTexture(guideTexture, j, i, mixFraction);
			}
		}
	}

	float CalculateHeightGuidanceTexture (Texture2D guideTex, int y, int x, float mixFraction)
	{
		float noiseVal = 0.0f;            
		float xfrac, yfrac;           
		float greyScaleVal;                  

		xfrac = (float)x / (float)edgeSize;
		yfrac = (float)y / (float)edgeSize;

		greyScaleVal = guideTex.GetPixelBilinear(xfrac, yfrac).grayscale;

		noiseVal = CalculateHeightOctaves(y, x);

		return (greyScaleVal*mixFraction) + noiseVal*(1-mixFraction);
	}

	float CalculateHeightOctaves(int y, int x)
	{
		float noiseVal = 0.0f;            
		float frequency = 1.0f;           
		float amplitude = 1.0f;          
		float maxValue = 0.0f;        

		for (int i = 0; i < octaves; i++)        
		{           
			float perlinX = noiseXstart + ((float)x / (float)edgeSize) * noiseXspan * frequency;           
			float perlinY = noiseYstart + ((float)y / (float)edgeSize) * noiseYspan * frequency;                        
			noiseVal += Mathf.PerlinNoise(perlinX, perlinY) * amplitude;   

			maxValue += amplitude;            
			amplitude *= persistence;            
			frequency *= 2;        
		}

		return noiseVal/maxValue;
	}

	//Code from Alastair Aitchison blog post
	// https://alastaira.wordpress.com/2013/11/14/procedural-terrain-splatmapping/
	void AssignSplatMap(TerrainData terrainData)
	{
		float height;
		float steepness;
		float frac;
		Vector3 normal;
		float[] splatWeights = new float[terrainData.alphamapLayers];

		splatmapData = new float[terrainData.alphamapWidth, terrainData.alphamapHeight, terrainData.alphamapLayers];

		for (int y = 0 ; y < terrainData.alphamapHeight ; y++)
		{
			for(int x = 0 ; x < terrainData.alphamapWidth ; x++)
			{
				//Get the normalized terrain coordinate that corresponds to the point
				float normX = (float)x/(float)terrainData.alphamapWidth;
				float normY = (float)y/(float)terrainData.alphamapHeight;

				height = terrainData.GetHeight(Mathf.RoundToInt(normY * terrainData.heightmapHeight), Mathf.RoundToInt(normX * terrainData.heightmapWidth));

				normal = terrainData.GetInterpolatedNormal(normY, normX);

				steepness = terrainData.GetSteepness(normY, normX);

				// Texture[0] has constant influence
				splatWeights[0] = .6f;

				// Texture[1] is strongest on steep terrain
				frac = steepness / 90.0f;
				splatWeights[1] = frac;

				// Texture[2] is stronger at higher altitude
				if (height > 30f)
				{
					splatWeights[2] = Mathf.Clamp01(height/heightScale) * 2.0f;
				}
				else
				{
					splatWeights[2] = 0.0f;
				}

				float z = splatWeights.Sum();

				for (int i = 0 ; i < terrainData.alphamapLayers ; i++)
				{
					//normalize so that sum of all texture weights = 1
					splatWeights[i] /= z;

					//Assign this point to the splatmap array
					splatmapData[x, y, i] = splatWeights[i];
				}
			}
		}
		terrainData.SetAlphamaps(0, 0, splatmapData);
	}

	public void PlaceTreesAcrossTerrain(int numTrees)
	{
		float treeX = 0;
		float treeZ = 0;
		int placedTrees = 0;

		while(placedTrees < numTrees)
		{
			treeX = Random.Range(0f, 1f);
			treeZ = Random.Range(0f, 1f);

            if (terrain.terrainData.GetSteepness(treeX, treeZ) <= 20)
			{
				PlaceTree(treeX, treeZ);
				placedTrees++;
			}
		}
	}

	public void PlaceTree(float treeX, float treeZ)
	{
		TreeInstance myTreeInstance = new TreeInstance();
		Vector3 position = new Vector3(treeX, 0, treeZ);
		int numPrototypes = terrain.terrainData.treePrototypes.Length;
		int selectedPrototype = Random.Range(0, numPrototypes);
		float elevation = terrain.terrainData.GetHeight(Mathf.RoundToInt(treeX * terrain.terrainData.heightmapHeight), Mathf.RoundToInt(treeZ * terrain.terrainData.heightmapWidth));

		if(numPrototypes == 0) return; //Terrain editor does not have any tree prefabs loaded

		myTreeInstance.position = position;
		myTreeInstance.color = Color.white;
		myTreeInstance.lightmapColor = Color.white;
		myTreeInstance.prototypeIndex = selectedPrototype;
		if (elevation > 50)
			myTreeInstance.heightScale = 1.5f;
		else
			myTreeInstance.heightScale = 1f;
		myTreeInstance.widthScale = 1f;
		myTreeInstance.rotation = Random.Range(0f, 6.283185f);
		terrain.AddTreeInstance(myTreeInstance);
	}
}
